/**
 * Funky WebSocket - Real-time Connection Manager
 *
 * Manages a shared WebSocket connection for real-time updates:
 * - Single connection, multiple subscribers (channel multiplexing)
 * - Explicit initialization - must call init() then connect()
 * - Channel subscriptions with per-channel handlers
 * - Automatic reconnection with exponential backoff
 * - Page Visibility API integration (pause when hidden)
 * - Network status awareness (pause when offline)
 * - Session expiry handling
 *
 * Usage:
 *   Funky.WebSocket.init({ debug: false });
 *   Funky.WebSocket.connect();
 *   Funky.WebSocket.subscribe('my-channel', function(message) { ... });
 *
 * @version 2.0.0
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.WebSocket] Registry not found. Load namespace.js first.');
		return;
	}

	// ============================================
	// Configuration
	// ============================================

	var CONFIG = {
		url: null,                    // WebSocket URL (auto-detected if null)
		reconnectMin: 1000,           // Initial reconnect delay (1s)
		reconnectMax: 30000,          // Max reconnect delay (30s)
		reconnectMultiplier: 2,       // Exponential backoff multiplier
		maxRetries: 10,               // Max reconnection attempts before giving up
		heartbeatInterval: 25000,     // Client heartbeat interval (25s)
		debug: true,                  // Enable debug logging
		presenceEnabled: true,        // Enable presence message handling
		autoRestorePresence: true,    // Restore presence on reconnect
		trackLatency: true,           // Track message latency
		heartbeatWithPresence: true   // Include presence in heartbeat
	};

	// ============================================
	// Presence Message Types
	// ============================================

	var PRESENCE_MESSAGES = {
		JOIN: 'presence:join',
		LEAVE: 'presence:leave',
		STATUS: 'presence:status',
		TYPING: 'presence:typing',
		HEARTBEAT: 'presence:heartbeat',
		SYNC: 'presence:sync',
		USER_JOINED: 'presence:user_joined',
		USER_LEFT: 'presence:user_left',
		USER_STATUS: 'presence:user_status',
		CURSOR: 'presence:cursor'
	};

	// ============================================
	// State
	// ============================================

	var state = {
		socket: null,
		status: 'disconnected',       // 'disconnected', 'connecting', 'connected', 'reconnecting'
		reconnectAttempts: 0,
		reconnectTimer: null,
		heartbeatTimer: null,
		channels: {},                 // { channelName: { subscribed: bool, handlers: [fn, ...] } }
		handlers: {},                 // { messageType: [handler, ...] }
		lastPong: null,
		connectionId: null,
		initialized: false            // Whether init() has been called
	};

	// ============================================
	// Presence State
	// ============================================

	var _presenceHandlers = {};           // { messageType: [handler, ...] }
	var _lastPresenceChannels = [];       // Channels to rejoin on reconnect
	var _presenceUserId = null;
	var _presenceUserData = null;
	var _latencyHistory = [];
	var _maxLatencyHistory = 10;
	var _lastHeartbeatSent = null;

	// ============================================
	// Logging
	// ============================================

	function log() {
		var args = ['[Funky.WebSocket]'].concat(Array.prototype.slice.call(arguments));
		console.log.apply(console, args);
	}

	function warn() {
		var args = ['[Funky.WebSocket]'].concat(Array.prototype.slice.call(arguments));
		console.warn.apply(console, args);
	}

	// ============================================
	// URL Detection
	// ============================================

	function getWebSocketUrl() {
		if (CONFIG.url) return CONFIG.url;

		var protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';
		return protocol + '//' + window.location.host + '/ws/realtime';
	}

	// ============================================
	// Presence Message Routing
	// ============================================

	/**
	 * Register a handler for presence messages
	 * @param {string} type - Presence message type
	 * @param {Function} handler - Handler function
	 */
	function onPresence(type, handler) {
		if (!_presenceHandlers[type]) {
			_presenceHandlers[type] = [];
		}
		_presenceHandlers[type].push(handler);
		log('Presence handler registered for:', type);
	}

	/**
	 * Remove a presence handler
	 * @param {string} type - Presence message type
	 * @param {Function} handler - Handler function (optional, removes all if not provided)
	 */
	function offPresence(type, handler) {
		if (!_presenceHandlers[type]) return;

		if (handler) {
			_presenceHandlers[type] = _presenceHandlers[type].filter(function(h) {
				return h !== handler;
			});
		} else {
			delete _presenceHandlers[type];
		}
	}

	/**
	 * Route presence message to handlers
	 * @param {Object} message - Parsed message
	 * @private
	 */
	function routePresenceMessage(message) {
		if (!message || !message.type) return false;
		if (!CONFIG.presenceEnabled) return false;

		// Check if it's a presence message
		if (message.type.indexOf('presence:') !== 0) return false;

		var handlers = _presenceHandlers[message.type];
		if (handlers && handlers.length > 0) {
			handlers.forEach(function(handler) {
				try {
					handler(message);
				} catch (e) {
					warn('Presence handler error:', e);
				}
			});
		}

		// Also emit via PubSub for global listeners
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:websocket:presence', message);
			Funky.PubSub.emit('funky:websocket:' + message.type, message);
		}

		return true;
	}

	// ============================================
	// Presence Channel Tracking
	// ============================================

	/**
	 * Track channels for reconnection
	 * @param {string} channel - Channel name
	 * @param {string} action - 'join' or 'leave'
	 * @private
	 */
	function trackPresenceChannel(channel, action) {
		var index = _lastPresenceChannels.indexOf(channel);

		if (action === 'join' && index === -1) {
			_lastPresenceChannels.push(channel);
		} else if (action === 'leave' && index !== -1) {
			_lastPresenceChannels.splice(index, 1);
		}
	}

	/**
	 * Restore presence on reconnection
	 * @private
	 */
	function restorePresenceOnReconnect() {
		if (!CONFIG.autoRestorePresence) return;
		if (!_presenceUserId || _lastPresenceChannels.length === 0) return;

		log('Restoring presence for', _lastPresenceChannels.length, 'channels');

		_lastPresenceChannels.forEach(function(channel) {
			sendRaw({
				type: PRESENCE_MESSAGES.JOIN,
				channel: channel,
				userId: _presenceUserId,
				user: _presenceUserData,
				reconnected: true
			});
		});

		// Emit reconnect event for Presence module
		if (Funky.PubSub) {
			Funky.PubSub.emit('funky:websocket:reconnected', {
				channels: _lastPresenceChannels.slice()
			});
		}
	}

	/**
	 * Leave all presence channels before disconnect
	 * @private
	 */
	function leaveAllPresenceChannels() {
		if (_lastPresenceChannels.length === 0) return;

		_lastPresenceChannels.forEach(function(channel) {
			sendRaw({
				type: PRESENCE_MESSAGES.LEAVE,
				channel: channel,
				userId: _presenceUserId
			});
		});
	}

	// ============================================
	// Latency Tracking
	// ============================================

	/**
	 * Track message latency
	 * @param {number} latency - Round-trip latency in ms
	 * @private
	 */
	function trackLatency(latency) {
		if (!CONFIG.trackLatency) return;

		_latencyHistory.push(latency);
		if (_latencyHistory.length > _maxLatencyHistory) {
			_latencyHistory.shift();
		}
	}

	/**
	 * Get average latency
	 * @returns {number} Average latency in ms
	 */
	function getAverageLatency() {
		if (_latencyHistory.length === 0) return 0;

		var sum = _latencyHistory.reduce(function(a, b) {
			return a + b;
		}, 0);

		return Math.round(sum / _latencyHistory.length);
	}

	/**
	 * Get connection quality based on latency
	 * @returns {string} 'excellent', 'good', 'fair', 'poor'
	 */
	function getConnectionQuality() {
		var latency = getAverageLatency();

		if (latency === 0) return 'unknown';
		if (latency < 100) return 'excellent';
		if (latency < 300) return 'good';
		if (latency < 500) return 'fair';
		return 'poor';
	}

	// ============================================
	// Connection Management
	// ============================================

	function connect() {
		if (state.socket && (state.status === 'connected' || state.status === 'connecting')) {
			log('Already connected or connecting');
			return;
		}

		// Check if online
		if (!navigator.onLine) {
			log('Offline, will connect when online');
			state.status = 'disconnected';
			return;
		}

		var url = getWebSocketUrl();
		log('Connecting to', url);

		state.status = 'connecting';
		dispatchStatusChange();

		try {
			state.socket = new WebSocket(url);

			state.socket.onopen = handleOpen;
			state.socket.onclose = handleClose;
			state.socket.onerror = handleError;
			state.socket.onmessage = handleMessage;
		} catch (err) {
			warn('Connection failed:', err);
			scheduleReconnect();
		}
	}

	function disconnect(code, reason) {
		code = code || 1000;
		reason = reason || 'Client disconnect';

		log('Disconnecting:', reason);

		// Leave all presence channels gracefully before disconnect
		leaveAllPresenceChannels();

		// Clear timers
		clearTimeout(state.reconnectTimer);
		clearInterval(state.heartbeatTimer);
		state.reconnectTimer = null;
		state.heartbeatTimer = null;

		// Reset retry count (intentional disconnect)
		state.reconnectAttempts = 0;

		if (state.socket) {
			state.socket.onclose = null; // Prevent reconnect
			state.socket.close(code, reason);
			state.socket = null;
		}

		state.status = 'disconnected';
		state.connectionId = null;
		dispatchStatusChange();
	}

	function scheduleReconnect() {
		if (state.reconnectTimer) return;
		if (state.status === 'connected') return;

		state.reconnectAttempts++;

		if (state.reconnectAttempts > CONFIG.maxRetries) {
			warn('Max retries exceeded, giving up');
			state.status = 'disconnected';
			dispatchStatusChange();
			dispatchEvent('max_retries_exceeded', {});
			return;
		}

		// Calculate delay with exponential backoff
		var delay = Math.min(
			CONFIG.reconnectMin * Math.pow(CONFIG.reconnectMultiplier, state.reconnectAttempts - 1),
			CONFIG.reconnectMax
		);

		log('Scheduling reconnect in', delay, 'ms (attempt', state.reconnectAttempts, ')');

		state.status = 'reconnecting';
		dispatchStatusChange();

		state.reconnectTimer = setTimeout(function() {
			state.reconnectTimer = null;
			connect();
		}, delay);
	}

	// ============================================
	// Event Handlers
	// ============================================

	function handleOpen() {
		log('Connected');

		var wasReconnecting = state.reconnectAttempts > 0;

		state.status = 'connected';
		state.reconnectAttempts = 0;
		state.lastPong = Date.now();

		dispatchStatusChange();

		// Start heartbeat
		startHeartbeat();

		// Resubscribe to all channels
		Object.keys(state.channels).forEach(function(channel) {
			sendRaw({ type: 'subscribe', channel: channel });
			state.channels[channel].subscribed = true;
		});

		// Restore presence channels on reconnect
		if (wasReconnecting) {
			restorePresenceOnReconnect();
		}
	}

	function handleClose(event) {
		log('Connection closed:', event.code, event.reason);

		state.socket = null;
		state.connectionId = null;

		clearInterval(state.heartbeatTimer);
		state.heartbeatTimer = null;

		// Don't reconnect for intentional closes
		if (event.code === 1000) {
			state.status = 'disconnected';
			dispatchStatusChange();
			return;
		}

		// Don't reconnect for auth failures
		if (event.code === 4001) {
			log('Session expired, not reconnecting');
			state.status = 'disconnected';
			dispatchStatusChange();
			dispatchEvent('session_expired', { reason: event.reason });
			return;
		}

		// Schedule reconnect for unexpected closes
		scheduleReconnect();
	}

	function handleError(error) {
		warn('WebSocket error:', error);
	}

	function handleMessage(event) {
		var data;
		try {
			data = JSON.parse(event.data);
		} catch (err) {
			warn('Invalid JSON message:', event.data);
			return;
		}

		var type = data.type;
		log('Received:', type, data);

		// Route presence messages first
		if (routePresenceMessage(data)) {
			// Also dispatch to regular handlers
			dispatchEvent(type, data);
			return;
		}

		// Route channel messages to channel handlers
		routeChannelMessage(data);

		// Handle built-in message types
		switch (type) {
			case 'connected':
				state.connectionId = data.user_id;
				dispatchEvent('connected', data);
				break;

			case 'ping':
				sendRaw({ type: 'pong' });
				state.lastPong = Date.now();
				break;

			case 'pong':
				// Track latency from heartbeat response
				if (_lastHeartbeatSent) {
					var latency = Date.now() - _lastHeartbeatSent;
					trackLatency(latency);

					if (Funky.PubSub) {
						Funky.PubSub.emit('funky:websocket:latency', {
							latency: latency,
							quality: getConnectionQuality()
						});
					}
				}
				state.lastPong = Date.now();
				break;

			case 'subscribed':
				log('Subscribed to:', data.channel);
				dispatchEvent('subscribed', data);
				break;

			case 'unsubscribed':
				log('Unsubscribed from:', data.channel);
				dispatchEvent('unsubscribed', data);
				break;

			case 'session_valid':
				state.lastPong = Date.now();
				break;

			case 'session_expired':
				disconnect(4001, 'Session expired');
				dispatchEvent('session_expired', data);
				break;

			case 'error':
				warn('Server error:', data.message);
				dispatchEvent('error', data);
				break;

			default:
				// Dispatch to registered handlers
				dispatchEvent(type, data);
		}
	}

	// ============================================
	// Heartbeat
	// ============================================

	function startHeartbeat() {
		clearInterval(state.heartbeatTimer);

		state.heartbeatTimer = setInterval(function() {
			if (state.status !== 'connected') return;

			// Track when heartbeat was sent for latency measurement
			_lastHeartbeatSent = Date.now();

			// Build heartbeat message
			var heartbeatMsg = { type: 'heartbeat' };

			// Include presence info if configured
			if (CONFIG.heartbeatWithPresence && _presenceUserId) {
				heartbeatMsg.userId = _presenceUserId;
				heartbeatMsg.channels = _lastPresenceChannels.slice();
			}

			// Send heartbeat to check session
			sendRaw(heartbeatMsg);
		}, CONFIG.heartbeatInterval);
	}

	// ============================================
	// Channel Subscriptions
	// ============================================

	/**
	 * Subscribe to a channel with an optional handler
	 * @param {string} channel - Channel name to subscribe to
	 * @param {Function} [handler] - Optional handler for messages on this channel
	 * @returns {Function|undefined} Unsubscribe function if handler provided
	 */
	function subscribe(channel, handler) {
		if (!channel) return;

		// Initialize channel if not exists
		if (!state.channels[channel]) {
			state.channels[channel] = {
				subscribed: false,
				handlers: []
			};
		}

		// Add handler if provided
		if (typeof handler === 'function') {
			state.channels[channel].handlers.push(handler);
			log('Channel handler added:', channel);
		}

		// Send subscribe message if connected and not yet subscribed
		if (state.status === 'connected' && !state.channels[channel].subscribed) {
			sendRaw({ type: 'subscribe', channel: channel });
			state.channels[channel].subscribed = true;
		}

		log('Subscribed to channel:', channel);

		// Return unsubscribe function for convenience
		if (handler) {
			return function() {
				unsubscribe(channel, handler);
			};
		}
	}

	/**
	 * Unsubscribe from a channel or remove a specific handler
	 * @param {string} channel - Channel name
	 * @param {Function} [handler] - Specific handler to remove. If omitted, removes all handlers and unsubscribes.
	 */
	function unsubscribe(channel, handler) {
		if (!channel) return;

		var channelData = state.channels[channel];
		if (!channelData) return;

		if (handler) {
			// Remove specific handler
			channelData.handlers = channelData.handlers.filter(function(h) {
				return h !== handler;
			});
			log('Channel handler removed:', channel, '(', channelData.handlers.length, 'remaining)');

			// If no handlers left, unsubscribe from channel entirely
			if (channelData.handlers.length === 0) {
				unsubscribe(channel);
			}
		} else {
			// Remove channel entirely
			delete state.channels[channel];

			if (state.status === 'connected') {
				sendRaw({ type: 'unsubscribe', channel: channel });
			}

			log('Unsubscribed from channel:', channel);
		}
	}

	function getSubscriptions() {
		return Object.keys(state.channels);
	}

	/**
	 * Route message to channel handlers
	 * @param {Object} data - Parsed message data
	 * @private
	 */
	function routeChannelMessage(data) {
		if (!data.channel) return false;

		var channelData = state.channels[data.channel];

		// Call channel-specific handlers if any
		if (channelData && channelData.handlers.length > 0) {
			channelData.handlers.forEach(function(handler) {
				try {
					handler(data);
				} catch (err) {
					warn('Channel handler error for', data.channel, ':', err);
				}
			});
		}

		// Emit channel-specific PubSub events for loose coupling
		if (Funky.PubSub) {
			// Emit to channel (for components like Kanban that listen to channel)
			Funky.PubSub.emit('funky:ws:' + data.channel, data);

			// Also emit with message type suffix (for more specific routing)
			if (data.type) {
				Funky.PubSub.emit('funky:ws:' + data.channel + ':' + data.type, data);
			}
		}

		return channelData && channelData.handlers.length > 0;
	}

	// ============================================
	// Message Sending
	// ============================================

	function sendRaw(data) {
		if (!state.socket || state.socket.readyState !== WebSocket.OPEN) {
			warn('Cannot send, not connected');
			return false;
		}

		try {
			state.socket.send(JSON.stringify(data));
			return true;
		} catch (err) {
			warn('Send failed:', err);
			return false;
		}
	}

	function send(type, data) {
		return sendRaw(Object.assign({ type: type }, data || {}));
	}

	// ============================================
	// Event Handlers
	// ============================================

	function on(type, handler) {
		if (!state.handlers[type]) {
			state.handlers[type] = [];
		}
		state.handlers[type].push(handler);
		log('Handler registered for:', type);
	}

	function off(type, handler) {
		if (!state.handlers[type]) return;

		if (handler) {
			state.handlers[type] = state.handlers[type].filter(function(h) {
				return h !== handler;
			});
		} else {
			delete state.handlers[type];
		}
	}

	function dispatchEvent(type, data) {
		var handlers = state.handlers[type] || [];
		handlers.forEach(function(handler) {
			try {
				handler(data);
			} catch (err) {
				warn('Handler error for', type, ':', err);
			}
		});

		// Also dispatch DOM event for external listeners
		var event = new CustomEvent('funky.ws.' + type, { detail: data });
		document.dispatchEvent(event);
	}

	function dispatchStatusChange() {
		dispatchEvent('status_changed', { status: state.status });

		var event = new CustomEvent('funky.ws.status', { detail: { status: state.status } });
		document.dispatchEvent(event);
	}

	// ============================================
	// Status Methods
	// ============================================

	function isConnected() {
		return state.status === 'connected';
	}

	function getState() {
		return state.status;
	}

	function getConnectionId() {
		return state.connectionId;
	}

	// ============================================
	// Network & Visibility Handlers
	// ============================================

	function handleOnline() {
		log('Network online');
		if (state.status === 'disconnected' && state.reconnectAttempts < CONFIG.maxRetries) {
			connect();
		}
	}

	function handleOffline() {
		log('Network offline');
		// Don't disconnect, but stop reconnecting
		clearTimeout(state.reconnectTimer);
		state.reconnectTimer = null;
	}

	function handleVisibilityChange() {
		if (document.hidden) {
			log('Page hidden, pausing heartbeat');
			clearInterval(state.heartbeatTimer);
			state.heartbeatTimer = null;
		} else {
			log('Page visible');
			if (state.status === 'connected') {
				startHeartbeat();
			} else if (state.status === 'disconnected') {
				connect();
			}
		}
	}

	// ============================================
	// UI Notifications
	// ============================================

	var connectionBanner = null;

	function showSessionExpiredModal() {
		// Use Funky.Toast if available for immediate feedback
		if (Funky.Toast) {
			Funky.Toast.error('Your session has expired. Please log in again.', 'Session Expired');
		}

		// Redirect to login after brief delay
		setTimeout(function() {
			window.location.href = '/auth/login?expired=1';
		}, 2000);
	}

	function showConnectionLostBanner() {
		if (connectionBanner) return;

		connectionBanner = document.createElement('div');
		connectionBanner.id = 'ws-connection-banner';
		connectionBanner.className = 'ws-connection-banner ws-banner-error';
		connectionBanner.innerHTML = 
			'<div class="ws-banner-content">' +
			'<i class="fas fa-wifi-slash"></i> ' +
			'<span>Connection lost. Real-time updates paused.</span> ' +
			'<button type="button" class="btn btn-sm btn-outline-light ms-3" id="ws-retry-btn">' +
			'<i class="fas fa-sync-alt"></i> Retry' +
			'</button>' +
			'</div>';

		document.body.appendChild(connectionBanner);

		// Bind retry button
		var retryBtn = document.getElementById('ws-retry-btn');
		if (retryBtn) {
			retryBtn.addEventListener('click', function() {
				state.reconnectAttempts = 0;
				connect();
			});
		}
	}

	function hideConnectionBanner() {
		if (connectionBanner) {
			connectionBanner.remove();
			connectionBanner = null;
		}
	}

	function showReconnectingBanner() {
		if (!connectionBanner) {
			connectionBanner = document.createElement('div');
			connectionBanner.id = 'ws-connection-banner';
			document.body.appendChild(connectionBanner);
		}

		connectionBanner.className = 'ws-connection-banner ws-banner-warning';
		connectionBanner.innerHTML = 
			'<div class="ws-banner-content">' +
			'<i class="fas fa-spinner fa-spin"></i> ' +
			'<span>Reconnecting... (attempt ' + state.reconnectAttempts + '/' + CONFIG.maxRetries + ')</span>' +
			'</div>';
	}

	// Register internal event handlers for UI
	function setupUIHandlers() {
		on('session_expired', showSessionExpiredModal);
		on('max_retries_exceeded', showConnectionLostBanner);
		on('status_changed', function(data) {
			if (data.status === 'connected') {
				hideConnectionBanner();
			} else if (data.status === 'reconnecting') {
				showReconnectingBanner();
			}
		});
	}

	// ============================================
	// Initialization
	// ============================================

	var _listenersAdded = false;

	/**
	 * Initialize the WebSocket module
	 * Must be called before connect(). Does NOT auto-connect.
	 * @param {Object} [options] - Configuration options
	 * @param {string} [options.url] - WebSocket URL (auto-detected if null)
	 * @param {number} [options.reconnectMin] - Min reconnect delay ms
	 * @param {number} [options.reconnectMax] - Max reconnect delay ms
	 * @param {number} [options.maxRetries] - Max reconnection attempts
	 * @param {boolean} [options.debug] - Enable debug logging
	 */
	function init(options) {
		if (state.initialized) {
			log('Already initialized');
			return;
		}

		// Merge options with CONFIG
		if (options) {
			Object.assign(CONFIG, options);
		}

		// Listen for network status changes
		if (!_listenersAdded) {
			window.addEventListener('online', handleOnline);
			window.addEventListener('offline', handleOffline);

			// Listen for page visibility changes
			document.addEventListener('visibilitychange', handleVisibilityChange);

			// Listen for page unload to leave presence gracefully
			window.addEventListener('beforeunload', handleBeforeUnload);

			_listenersAdded = true;
		}

		// Setup UI handlers
		setupUIHandlers();

		state.initialized = true;
		log('Initialized');

		// NOTE: Does NOT auto-connect
		// The app must explicitly call connect() when ready
	}

	/**
	 * Configure options (can be called before or after init)
	 * @param {Object} options - Configuration options
	 */
	function configure(options) {
		Object.assign(CONFIG, options);
	}

	/**
	 * Check if WebSocket is initialized
	 * @returns {boolean}
	 */
	function isInitialized() {
		return state.initialized;
	}

	/**
	 * Destroy WebSocket module and remove all listeners
	 */
	function destroy() {
		// Disconnect if connected
		disconnect();

		// Remove global event listeners
		if (_listenersAdded) {
			window.removeEventListener('online', handleOnline);
			window.removeEventListener('offline', handleOffline);
			document.removeEventListener('visibilitychange', handleVisibilityChange);
			window.removeEventListener('beforeunload', handleBeforeUnload);
			_listenersAdded = false;
		}

		// Clear all handlers and channels
		state.handlers = {};
		state.channels = {};
		state.initialized = false;
		_presenceHandlers = {};
		_lastPresenceChannels = [];
		log('Destroyed');
	}

	// ============================================
	// Presence Helper Methods
	// ============================================

	/**
	 * Set user data for presence
	 * @param {Object} data - User data (id, name, avatar)
	 */
	function setPresenceUser(data) {
		if (!data || !data.id) {
			warn('setPresenceUser requires data with id');
			return;
		}

		_presenceUserId = data.id;
		_presenceUserData = data;
		log('Presence user set:', data.id);
	}

	/**
	 * Get current presence user
	 * @returns {Object|null}
	 */
	function getPresenceUser() {
		return _presenceUserData;
	}

	/**
	 * Send a presence join message
	 * @param {string} channel - Channel name
	 * @param {Object} options - Join options
	 * @returns {boolean} Success
	 */
	function presenceJoin(channel, options) {
		if (!channel) {
			warn('presenceJoin requires channel');
			return false;
		}

		options = options || {};

		var message = {
			type: PRESENCE_MESSAGES.JOIN,
			channel: channel,
			userId: _presenceUserId,
			user: _presenceUserData,
			status: options.status || 'viewing',
			metadata: options.metadata || {}
		};

		var sent = sendRaw(message);
		if (sent) {
			trackPresenceChannel(channel, 'join');
		}
		return sent;
	}

	/**
	 * Send a presence leave message
	 * @param {string} channel - Channel name
	 * @returns {boolean} Success
	 */
	function presenceLeave(channel) {
		if (!channel) {
			warn('presenceLeave requires channel');
			return false;
		}

		var message = {
			type: PRESENCE_MESSAGES.LEAVE,
			channel: channel,
			userId: _presenceUserId
		};

		var sent = sendRaw(message);
		trackPresenceChannel(channel, 'leave');
		return sent;
	}

	/**
	 * Send a presence status update
	 * @param {string} channel - Channel name
	 * @param {string} status - New status
	 * @param {Object} metadata - Optional metadata update
	 * @returns {boolean} Success
	 */
	function presenceStatus(channel, status, metadata) {
		if (!channel || !status) {
			warn('presenceStatus requires channel and status');
			return false;
		}

		var message = {
			type: PRESENCE_MESSAGES.STATUS,
			channel: channel,
			userId: _presenceUserId,
			status: status
		};

		if (metadata) {
			message.metadata = metadata;
		}

		return sendRaw(message);
	}

	/**
	 * Send a typing indicator
	 * @param {string} channel - Channel name
	 * @param {boolean} typing - Is typing
	 * @returns {boolean} Success
	 */
	function presenceTyping(channel, typing) {
		if (!channel) {
			warn('presenceTyping requires channel');
			return false;
		}

		return sendRaw({
			type: PRESENCE_MESSAGES.TYPING,
			channel: channel,
			userId: _presenceUserId,
			user: _presenceUserData,
			typing: typing !== false
		});
	}

	/**
	 * Send cursor position
	 * @param {string} channel - Channel name
	 * @param {Object} position - Cursor position data
	 * @returns {boolean} Success
	 */
	function presenceCursor(channel, position) {
		if (!channel) {
			warn('presenceCursor requires channel');
			return false;
		}

		return sendRaw({
			type: PRESENCE_MESSAGES.CURSOR,
			channel: channel,
			userId: _presenceUserId,
			user: _presenceUserData,
			position: position
		});
	}

	/**
	 * Send a presence heartbeat
	 * @returns {boolean} Success
	 */
	function presenceHeartbeat() {
		return sendRaw({
			type: PRESENCE_MESSAGES.HEARTBEAT,
			userId: _presenceUserId,
			timestamp: new Date().toISOString(),
			channels: _lastPresenceChannels.slice()
		});
	}

	/**
	 * Get all presence channels the user is currently in
	 * @returns {Array<string>}
	 */
	function getPresenceChannels() {
		return _lastPresenceChannels.slice();
	}

	// ============================================
	// Beforeunload Handler
	// ============================================

	/**
	 * Handle page unload - leave presence channels gracefully
	 */
	function handleBeforeUnload() {
		leaveAllPresenceChannels();
	}

	// ============================================
	// Public API
	// ============================================

	var FunkyWebSocket = {
		// Initialization
		init: init,
		isInitialized: isInitialized,
		configure: configure,

		// Connection
		connect: connect,
		disconnect: disconnect,
		destroy: destroy,

		// Channels
		subscribe: subscribe,
		unsubscribe: unsubscribe,
		getSubscriptions: getSubscriptions,

		// Messaging
		send: send,
		on: on,
		off: off,

		// Status
		isConnected: isConnected,
		getState: getState,
		getConnectionId: getConnectionId,

		// Presence Message Types
		PRESENCE_MESSAGES: PRESENCE_MESSAGES,

		// Presence Handlers
		onPresence: onPresence,
		offPresence: offPresence,

		// Presence User
		setPresenceUser: setPresenceUser,
		getPresenceUser: getPresenceUser,

		// Presence Actions
		presenceJoin: presenceJoin,
		presenceLeave: presenceLeave,
		presenceStatus: presenceStatus,
		presenceTyping: presenceTyping,
		presenceCursor: presenceCursor,
		presenceHeartbeat: presenceHeartbeat,
		getPresenceChannels: getPresenceChannels,

		// Connection Quality
		getAverageLatency: getAverageLatency,
		getConnectionQuality: getConnectionQuality,

		// Debug
		getDebugState: function() {
			return {
				status: state.status,
				reconnectAttempts: state.reconnectAttempts,
				channels: Object.keys(state.channels),
				handlerTypes: Object.keys(state.handlers),
				connectionId: state.connectionId,
				lastPong: state.lastPong,
				presenceUserId: _presenceUserId,
				presenceChannels: _lastPresenceChannels.slice(),
				averageLatency: getAverageLatency(),
				connectionQuality: getConnectionQuality()
			};
		}
	};

	// Register with Funky namespace (do NOT auto-init)
	// Apps must explicitly call Funky.WebSocket.init() then connect()
	Funky.register('WebSocket', FunkyWebSocket);

})(window);

/**
 * PAGI Chat - Multi-User Chat Demo
 *
 * Vanilla JavaScript frontend for the PAGI chat showcase application.
 * Demonstrates WebSocket, SSE, and HTTP API integration.
 */

(function() {
    'use strict';

    // ===== State =====
    const state = {
        username: '',
        userId: '',
        sessionId: '',          // Persistent session ID for reconnection
        currentRoom: 'general',
        rooms: {},
        users: {},
        ws: null,
        sse: null,
        typingTimeout: null,
        isTyping: false,
        reconnectAttempts: 0,
        maxReconnectDelay: 30000,   // Max 30 seconds between attempts
        pingInterval: null,
        pingIntervalMs: 10000,      // Send ping every 10 seconds
        lastPongTime: 0,            // Track last pong received
        heartbeatCheckInterval: null,
        heartbeatTimeoutMs: 35000,  // Consider connection dead if no pong in 35s
        lastMsgId: 0                // Track last received message ID for catch-up
    };

    // ===== DOM Elements =====
    const elements = {
        // Screens
        loginScreen: document.getElementById('login-screen'),
        chatScreen: document.getElementById('chat-screen'),

        // Login
        loginForm: document.getElementById('login-form'),
        usernameInput: document.getElementById('username'),

        // Sidebar
        themeToggle: document.getElementById('theme-toggle'),
        connectionStatus: document.getElementById('connection-status'),
        displayName: document.getElementById('display-name'),
        userAvatar: document.getElementById('user-avatar'),
        roomsList: document.getElementById('rooms-list'),
        usersList: document.getElementById('users-list'),
        userCount: document.getElementById('user-count'),
        createRoomBtn: document.getElementById('create-room-btn'),

        // Stats
        statUsers: document.getElementById('stat-users'),
        statRooms: document.getElementById('stat-rooms'),
        statUptime: document.getElementById('stat-uptime'),

        // Chat
        currentRoomName: document.getElementById('current-room-name'),
        typingIndicator: document.getElementById('typing-indicator'),
        leaveRoomBtn: document.getElementById('leave-room-btn'),
        messagesContainer: document.getElementById('messages-container'),
        messages: document.getElementById('messages'),
        messageForm: document.getElementById('message-form'),
        messageInput: document.getElementById('message-input'),

        // Modal
        createRoomModal: document.getElementById('create-room-modal'),
        createRoomForm: document.getElementById('create-room-form'),
        roomNameInput: document.getElementById('room-name'),
        cancelCreateRoom: document.getElementById('cancel-create-room'),

        // Toast
        toastContainer: document.getElementById('toast-container')
    };

    // ===== Theme Management =====
    function initTheme() {
        const savedTheme = localStorage.getItem('theme') || 'light';
        document.documentElement.setAttribute('data-theme', savedTheme);
        updateThemeIcon(savedTheme);
    }

    function toggleTheme() {
        const current = document.documentElement.getAttribute('data-theme');
        const next = current === 'dark' ? 'light' : 'dark';
        document.documentElement.setAttribute('data-theme', next);
        localStorage.setItem('theme', next);
        updateThemeIcon(next);
    }

    function updateThemeIcon(theme) {
        const sunIcon = elements.themeToggle.querySelector('.icon-sun');
        const moonIcon = elements.themeToggle.querySelector('.icon-moon');
        if (theme === 'dark') {
            sunIcon.classList.add('hidden');
            moonIcon.classList.remove('hidden');
        } else {
            sunIcon.classList.remove('hidden');
            moonIcon.classList.add('hidden');
        }
    }

    // ===== Connection Status =====
    function setConnectionStatus(status, extraInfo = '') {
        const el = elements.connectionStatus;
        const text = el.querySelector('.status-text');

        el.classList.remove('connected', 'disconnected');

        switch (status) {
            case 'connected':
                el.classList.add('connected');
                text.textContent = 'Connected';
                break;
            case 'disconnected':
                el.classList.add('disconnected');
                text.textContent = 'Disconnected';
                break;
            case 'connecting':
                text.textContent = 'Connecting...';
                break;
            case 'reconnecting':
                text.textContent = `Reconnecting...`;
                break;
        }
    }

    // ===== Toast Notifications =====
    function showToast(message, type = 'info') {
        const toast = document.createElement('div');
        toast.className = `toast ${type}`;
        toast.textContent = message;

        elements.toastContainer.appendChild(toast);

        setTimeout(() => {
            toast.style.animation = 'slideIn 0.3s ease reverse';
            setTimeout(() => toast.remove(), 300);
        }, 3000);
    }

    // ===== Exponential Backoff =====
    function calculateReconnectDelay() {
        // Formula: min(1000 * 2^attempts + random(0, 1000), 30000)
        const baseDelay = 1000 * Math.pow(2, state.reconnectAttempts);
        const jitter = Math.random() * 1000;
        return Math.min(baseDelay + jitter, state.maxReconnectDelay);
    }

    // ===== Session Management =====
    function getOrCreateSessionId() {
        let sessionId = localStorage.getItem('chat-session-id');
        if (!sessionId) {
            sessionId = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
            localStorage.setItem('chat-session-id', sessionId);
        }
        return sessionId;
    }

    function clearSession() {
        localStorage.removeItem('chat-session-id');
        state.sessionId = '';
        state.lastMsgId = 0;
    }

    // ===== WebSocket Connection =====
    function connectWebSocket() {
        const protocol = window.location.protocol === 'https:' ? 'wss:' : 'ws:';

        // Get or create persistent session ID
        state.sessionId = getOrCreateSessionId();

        // Build connection URL with session info for resume support
        const params = new URLSearchParams({
            name: state.username,
            session: state.sessionId,
            lastMsgId: state.lastMsgId.toString()
        });
        const wsUrl = `${protocol}//${window.location.host}/ws/chat?${params}`;

        setConnectionStatus(state.reconnectAttempts > 0 ? 'reconnecting' : 'connecting');

        state.ws = new WebSocket(wsUrl);

        state.ws.onopen = () => {
            setConnectionStatus('connected');
            state.reconnectAttempts = 0;
            state.lastPongTime = Date.now();

            // Start keepalive ping interval
            if (state.pingInterval) {
                clearInterval(state.pingInterval);
            }
            state.pingInterval = setInterval(() => {
                if (state.ws && state.ws.readyState === WebSocket.OPEN) {
                    sendMessage({ type: 'ping' });
                }
            }, state.pingIntervalMs);

            // Start heartbeat timeout check
            if (state.heartbeatCheckInterval) {
                clearInterval(state.heartbeatCheckInterval);
            }
            state.heartbeatCheckInterval = setInterval(() => {
                const timeSinceLastPong = Date.now() - state.lastPongTime;
                if (timeSinceLastPong > state.heartbeatTimeoutMs) {
                    console.warn('Heartbeat timeout - connection appears dead, reconnecting...');
                    if (state.ws) {
                        state.ws.close();
                    }
                }
            }, 5000); // Check every 5 seconds
        };

        state.ws.onclose = (event) => {
            setConnectionStatus('disconnected');

            // Clear intervals
            if (state.pingInterval) {
                clearInterval(state.pingInterval);
                state.pingInterval = null;
            }
            if (state.heartbeatCheckInterval) {
                clearInterval(state.heartbeatCheckInterval);
                state.heartbeatCheckInterval = null;
            }

            // Always try to reconnect with exponential backoff
            state.reconnectAttempts++;
            const delay = calculateReconnectDelay();
            console.log(`Reconnecting in ${Math.round(delay)}ms (attempt ${state.reconnectAttempts})...`);
            setConnectionStatus('reconnecting');
            setTimeout(connectWebSocket, delay);
        };

        state.ws.onerror = (error) => {
            console.error('WebSocket error:', error);
        };

        state.ws.onmessage = (event) => {
            // Any message resets the heartbeat timer
            state.lastPongTime = Date.now();

            try {
                const data = JSON.parse(event.data);
                handleWebSocketMessage(data);
            } catch (e) {
                console.error('Failed to parse message:', e);
            }
        };
    }

    function handleWebSocketMessage(data) {
        // Track message IDs for catch-up on reconnect
        if (data.id && data.id > state.lastMsgId) {
            state.lastMsgId = data.id;
        }

        switch (data.type) {
            case 'connected':
                // New connection - store session info
                state.userId = data.user_id;
                state.sessionId = data.session_id;
                state.username = data.name;
                localStorage.setItem('chat-session-id', data.session_id);
                updateUserInfo();
                updateRoomsList(data.rooms.map(name => ({ name, users: 0 })));
                break;

            case 'resumed':
                // Session resumed after reconnect
                state.userId = data.session_id;  // session_id is the user_id
                state.sessionId = data.session_id;
                state.username = data.name;
                localStorage.setItem('chat-session-id', data.session_id);
                updateUserInfo();

                // Restore room state
                state.rooms = {};
                data.rooms.forEach(room => state.rooms[room] = true);

                // Apply missed messages
                if (data.missedMessages) {
                    for (const [room, messages] of Object.entries(data.missedMessages)) {
                        if (room === state.currentRoom) {
                            messages.forEach(msg => {
                                if (msg.type === 'system') {
                                    addSystemMessage(msg.text, false);
                                } else {
                                    addMessage(msg, false);
                                }
                                // Track highest message ID
                                if (msg.id && msg.id > state.lastMsgId) {
                                    state.lastMsgId = msg.id;
                                }
                            });
                            scrollToBottom();
                        }
                    }
                }

                updateRoomsList(data.rooms.map(name => ({ name, users: 0 })));
                showToast('Session resumed', 'success');
                break;

            case 'joined':
                state.rooms[data.room] = true;
                state.currentRoom = data.room;
                updateCurrentRoom();
                renderMessages(data.history || []);
                // Track highest message ID from history
                if (data.history) {
                    data.history.forEach(msg => {
                        if (msg.id && msg.id > state.lastMsgId) {
                            state.lastMsgId = msg.id;
                        }
                    });
                }
                updateUsersList(data.users || []);
                updateRoomsList();
                break;

            case 'left':
                delete state.rooms[data.room];
                // Switch to general if we left current room
                if (state.currentRoom === data.room) {
                    state.currentRoom = 'general';
                    updateCurrentRoom();
                    sendMessage({ type: 'get_history', room: 'general' });
                }
                updateRoomsList();
                break;

            case 'message':
            case 'action':
                // Track message ID for catch-up
                if (data.id && data.id > state.lastMsgId) {
                    state.lastMsgId = data.id;
                }
                if (data.room === state.currentRoom) {
                    addMessage(data);
                    // Clear typing indicator for this user since they sent a message
                    updateTypingIndicator(data.from, false);
                }
                break;

            case 'system':
                if (data.room === state.currentRoom) {
                    addSystemMessage(data.text);
                }
                break;

            case 'user_joined':
                if (data.room === state.currentRoom) {
                    addSystemMessage(`${data.user} joined the room`);
                    updateUsersList(data.users || []);
                }
                updateRoomsList();
                break;

            case 'user_left':
                if (data.room === state.currentRoom) {
                    addSystemMessage(`${data.user} left the room`);
                    updateUsersList(data.users || []);
                }
                updateRoomsList();
                break;

            case 'typing':
                if (data.room === state.currentRoom) {
                    updateTypingIndicator(data.user, data.typing);
                }
                break;

            case 'pm':
                addPrivateMessage(data, 'received');
                showToast(`Private message from ${data.from}`, 'info');
                break;

            case 'pm_sent':
                addPrivateMessage({ from: 'You', to: data.to, text: data.text, ts: data.ts }, 'sent');
                break;

            case 'nick_changed':
                if (data.old_name === state.username) {
                    state.username = data.new_name;
                    updateUserInfo();
                    showToast(`You are now known as ${data.new_name}`, 'success');
                } else if (data.room === state.currentRoom) {
                    addSystemMessage(`${data.old_name} is now known as ${data.new_name}`);
                    updateUsersList(data.users || []);
                }
                break;

            case 'room_list':
                updateRoomsList(data.rooms);
                break;

            case 'user_list':
                if (data.room === state.currentRoom) {
                    updateUsersList(data.users);
                }
                break;

            case 'history':
                if (data.room === state.currentRoom) {
                    renderMessages(data.messages || []);
                }
                break;

            case 'error':
                showToast(data.message, 'error');
                break;

            case 'pong':
            case 'server_ping':
                // Keepalive messages - no action needed
                break;
        }
    }

    function sendMessage(data) {
        if (state.ws && state.ws.readyState === WebSocket.OPEN) {
            state.ws.send(JSON.stringify(data));
        }
    }

    // ===== SSE Connection =====
    function connectSSE() {
        state.sse = new EventSource('/events');

        state.sse.addEventListener('stats', (event) => {
            try {
                const stats = JSON.parse(event.data);
                updateStats(stats);
            } catch (e) {
                console.error('Failed to parse stats:', e);
            }
        });

        state.sse.addEventListener('user_connected', (event) => {
            try {
                const data = JSON.parse(event.data);
                elements.statUsers.textContent = data.count;
            } catch (e) {}
        });

        state.sse.addEventListener('user_disconnected', (event) => {
            try {
                const data = JSON.parse(event.data);
                elements.statUsers.textContent = data.count;
            } catch (e) {}
        });

        state.sse.onerror = () => {
            // SSE will auto-reconnect
        };
    }

    function updateStats(stats) {
        elements.statUsers.textContent = stats.users_online;
        elements.statRooms.textContent = stats.rooms_count;
        elements.statUptime.textContent = formatUptime(stats.uptime);
    }

    function formatUptime(seconds) {
        if (seconds < 60) return `${seconds}s`;
        if (seconds < 3600) return `${Math.floor(seconds / 60)}m`;
        if (seconds < 86400) return `${Math.floor(seconds / 3600)}h`;
        return `${Math.floor(seconds / 86400)}d`;
    }

    // ===== UI Updates =====
    function updateUserInfo() {
        elements.displayName.textContent = state.username;
        elements.userAvatar.textContent = state.username.charAt(0).toUpperCase();
    }

    function updateCurrentRoom() {
        elements.currentRoomName.textContent = `#${state.currentRoom}`;
        elements.leaveRoomBtn.classList.toggle('hidden', state.currentRoom === 'general');
        elements.messages.innerHTML = '';

        // Highlight active room
        document.querySelectorAll('#rooms-list li').forEach(li => {
            li.classList.toggle('active', li.dataset.room === state.currentRoom);
        });
    }

    function updateRoomsList(rooms) {
        if (rooms) {
            state.roomsData = rooms;
        }

        const roomsData = state.roomsData || [];
        elements.roomsList.innerHTML = roomsData.map(room => `
            <li data-room="${escapeHtml(room.name)}"
                class="${room.name === state.currentRoom ? 'active' : ''}">
                <span>#${escapeHtml(room.name)}</span>
                <span class="room-users">${room.users}</span>
            </li>
        `).join('');

        // Add click handlers
        elements.roomsList.querySelectorAll('li').forEach(li => {
            li.addEventListener('click', () => {
                const roomName = li.dataset.room;
                if (roomName !== state.currentRoom) {
                    if (!state.rooms[roomName]) {
                        sendMessage({ type: 'join', room: roomName });
                    } else {
                        state.currentRoom = roomName;
                        updateCurrentRoom();
                        sendMessage({ type: 'get_history', room: roomName });
                        sendMessage({ type: 'get_users', room: roomName });
                    }
                }
            });
        });
    }

    function updateUsersList(users) {
        state.users = {};
        users.forEach(u => state.users[u.id] = u);

        elements.userCount.textContent = users.length;
        elements.usersList.innerHTML = users.map(user => `
            <li data-user-id="${escapeHtml(user.id)}">
                <span class="user-avatar" style="width: 24px; height: 24px; font-size: 0.75rem;">
                    ${escapeHtml(user.name.charAt(0).toUpperCase())}
                </span>
                <span>${escapeHtml(user.name)}${user.id === state.userId ? ' (you)' : ''}</span>
                ${user.typing ? '<span class="typing-dot"></span>' : ''}
            </li>
        `).join('');
    }

    function updateTypingIndicator(user, isTyping) {
        // Track who's typing
        if (!state.typingUsers) state.typingUsers = new Set();

        if (isTyping) {
            state.typingUsers.add(user);
        } else {
            state.typingUsers.delete(user);
        }

        const typingList = Array.from(state.typingUsers);
        if (typingList.length === 0) {
            elements.typingIndicator.classList.add('hidden');
        } else if (typingList.length === 1) {
            elements.typingIndicator.textContent = `${typingList[0]} is typing...`;
            elements.typingIndicator.classList.remove('hidden');
        } else if (typingList.length <= 3) {
            elements.typingIndicator.textContent = `${typingList.join(', ')} are typing...`;
            elements.typingIndicator.classList.remove('hidden');
        } else {
            elements.typingIndicator.textContent = 'Several people are typing...';
            elements.typingIndicator.classList.remove('hidden');
        }
    }

    // ===== Message Rendering =====
    function renderMessages(messages) {
        elements.messages.innerHTML = '';
        messages.forEach(msg => {
            if (msg.type === 'system') {
                addSystemMessage(msg.text, false);
            } else {
                addMessage(msg, false);
            }
        });
        scrollToBottom();
    }

    function addMessage(data, scroll = true) {
        const isOwn = data.from === state.username;
        const msgEl = document.createElement('div');
        msgEl.className = `message ${isOwn ? 'own' : 'other'} ${data.type === 'action' ? 'action' : ''}`;

        if (data.type === 'action') {
            msgEl.innerHTML = `<span class="message-text">${escapeHtml(data.text)}</span>`;
        } else {
            msgEl.innerHTML = `
                <div class="message-header">
                    <span class="message-author">${escapeHtml(data.from)}</span>
                    <span class="message-time">${formatTime(data.ts)}</span>
                </div>
                <div class="message-text">${formatMessageText(data.text)}</div>
            `;
        }

        elements.messages.appendChild(msgEl);
        if (scroll) scrollToBottom();
    }

    function addSystemMessage(text, scroll = true) {
        const msgEl = document.createElement('div');
        msgEl.className = 'message system';
        msgEl.innerHTML = `<span class="message-text">${escapeHtml(text)}</span>`;

        elements.messages.appendChild(msgEl);
        if (scroll) scrollToBottom();
    }

    function addPrivateMessage(data, direction) {
        const msgEl = document.createElement('div');
        msgEl.className = `message pm ${direction === 'sent' ? 'own' : 'other'}`;

        const label = direction === 'sent' ? `To ${data.to}` : `From ${data.from}`;

        msgEl.innerHTML = `
            <div class="message-header">
                <span class="message-author">[PM] ${escapeHtml(label)}</span>
                <span class="message-time">${formatTime(data.ts)}</span>
            </div>
            <div class="message-text">${formatMessageText(data.text)}</div>
        `;

        elements.messages.appendChild(msgEl);
        scrollToBottom();
    }

    function scrollToBottom() {
        elements.messagesContainer.scrollTop = elements.messagesContainer.scrollHeight;
    }

    function formatTime(ts) {
        if (!ts) return '';
        const date = new Date(ts * 1000);
        return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }

    function formatMessageText(text) {
        // Escape HTML first
        text = escapeHtml(text);

        // Convert newlines to <br> for multiline messages (like /help output)
        text = text.replace(/\n/g, '<br>');

        // Simple URL detection
        text = text.replace(
            /(https?:\/\/[^\s<]+)/g,
            '<a href="$1" target="_blank" rel="noopener">$1</a>'
        );

        return text;
    }

    function escapeHtml(text) {
        if (!text) return '';
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    // ===== Typing Indicator =====
    function handleTyping() {
        if (!state.isTyping) {
            state.isTyping = true;
            sendMessage({
                type: 'typing',
                room: state.currentRoom,
                typing: true
            });
        }

        // Clear existing timeout
        if (state.typingTimeout) {
            clearTimeout(state.typingTimeout);
        }

        // Stop typing after 2 seconds of inactivity
        state.typingTimeout = setTimeout(() => {
            state.isTyping = false;
            sendMessage({
                type: 'typing',
                room: state.currentRoom,
                typing: false
            });
        }, 2000);
    }

    // ===== Event Handlers =====
    function initEventHandlers() {
        // Theme toggle
        elements.themeToggle.addEventListener('click', toggleTheme);

        // Visibility change - send ping when tab becomes visible
        // This helps prevent disconnects from browser throttling background tabs
        document.addEventListener('visibilitychange', () => {
            if (document.visibilityState === 'visible') {
                // Tab became visible - send immediate ping to keep connection alive
                if (state.ws && state.ws.readyState === WebSocket.OPEN) {
                    sendMessage({ type: 'ping' });
                }
            }
        });

        // Login form
        elements.loginForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const username = elements.usernameInput.value.trim();
            if (username) {
                state.username = username;
                elements.loginScreen.classList.add('hidden');
                elements.chatScreen.classList.remove('hidden');
                connectWebSocket();
                connectSSE();
            }
        });

        // Message form
        elements.messageForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const text = elements.messageInput.value.trim();
            if (text) {
                sendMessage({
                    type: 'message',
                    room: state.currentRoom,
                    text: text
                });
                elements.messageInput.value = '';

                // Stop typing indicator
                if (state.typingTimeout) {
                    clearTimeout(state.typingTimeout);
                }
                state.isTyping = false;
            }
        });

        // Typing detection
        elements.messageInput.addEventListener('input', handleTyping);

        // Leave room button
        elements.leaveRoomBtn.addEventListener('click', () => {
            sendMessage({ type: 'leave', room: state.currentRoom });
        });

        // Create room button
        elements.createRoomBtn.addEventListener('click', () => {
            elements.createRoomModal.classList.remove('hidden');
            elements.roomNameInput.focus();
        });

        // Cancel create room
        elements.cancelCreateRoom.addEventListener('click', () => {
            elements.createRoomModal.classList.add('hidden');
            elements.roomNameInput.value = '';
        });

        // Modal backdrop click
        elements.createRoomModal.querySelector('.modal-backdrop').addEventListener('click', () => {
            elements.createRoomModal.classList.add('hidden');
            elements.roomNameInput.value = '';
        });

        // Create room form
        elements.createRoomForm.addEventListener('submit', (e) => {
            e.preventDefault();
            const roomName = elements.roomNameInput.value.trim().toLowerCase();
            if (roomName) {
                sendMessage({ type: 'join', room: roomName });
                elements.createRoomModal.classList.add('hidden');
                elements.roomNameInput.value = '';
            }
        });

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            // Escape to close modal
            if (e.key === 'Escape') {
                elements.createRoomModal.classList.add('hidden');
            }

            // Focus message input when typing
            if (e.target === document.body && !e.ctrlKey && !e.metaKey && !e.altKey) {
                if (e.key.length === 1 && !elements.loginScreen.classList.contains('hidden') === false) {
                    elements.messageInput.focus();
                }
            }
        });
    }

    // ===== Initialization =====
    function init() {
        initTheme();
        initEventHandlers();

        // Focus username input
        elements.usernameInput.focus();

        // Auto-fill username from localStorage if available
        const savedUsername = localStorage.getItem('chat-username');
        if (savedUsername) {
            elements.usernameInput.value = savedUsername;
        }

        // Save username on login
        elements.loginForm.addEventListener('submit', () => {
            localStorage.setItem('chat-username', elements.usernameInput.value.trim());
        });
    }

    // Start the app
    document.addEventListener('DOMContentLoaded', init);
})();

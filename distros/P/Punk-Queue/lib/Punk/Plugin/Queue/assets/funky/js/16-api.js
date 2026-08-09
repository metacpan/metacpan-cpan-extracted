/**
 * Funky API - Centralized API Layer
 * 
 * Single entry point for all API calls with:
 * - Automatic CSRF token injection
 * - Global error handling (401 → session:expired, 403 → toast, etc.)
 * - Request deduplication
 * - Request cancellation on SPA navigation
 * - Retry logic for 503 errors
 * - Timeout handling with AbortController
 * - Event emission (api:request, api:success, api:error)
 * 
 * Usage:
 *   Funky.Api.get('/api/clients');
 *   Funky.Api.post('/api/clients', { name: 'Acme Corp' });
 *   Funky.Api.clients.list();
 *   Funky.Api.clients.update(id, data);
 */
(function(window) {
	'use strict';

	// Ensure Funky registry exists
	if (!window.Funky || !window.Funky.register) {
		console.error('[Funky.Api] Registry not found. Load namespace.js first.');
		return;
	}

	// ============================================
	// CONFIGURATION
	// ============================================

	var config = {
		timeout: 30000, // 30 second default timeout
		maxRetries: 3, // Max retries for 503 errors
		retryDelay: 1000, // Initial retry delay (doubles each retry)
		deduplicateGET: true // Deduplicate identical GET requests
	};

	// ============================================
	// INTERNAL STATE
	// ============================================

	// Map of pending requests for deduplication: url+method → { promise, controller }
	var pendingRequests = {};

	// Set of AbortControllers for SPA navigation cancellation
	var activeControllers = new Set();

	// ============================================
	// HELPER FUNCTIONS
	// ============================================

	/**
	 * Get CSRF token from cookie
	 */
	function getCsrfToken() {
		var name = 'csrf_token=';
		var decodedCookie = decodeURIComponent(document.cookie);
		var cookieArray = decodedCookie.split(';');

		for (var i = 0; i < cookieArray.length; i++) {
			var cookie = cookieArray[i].trim();
			if (cookie.indexOf(name) === 0) {
				return cookie.substring(name.length, cookie.length);
			}
		}
		return null;
	}

	/**
	 * Build a unique key for request deduplication
	 */
	function getRequestKey(url, method) {
		return method.toUpperCase() + ':' + url;
	}

	/**
	 * Sleep for specified milliseconds
	 */
	function sleep(ms) {
		return new Promise(function(resolve) {
			setTimeout(resolve, ms);
		});
	}

	/**
	 * Parse JSON response, handling empty responses
	 */
	function parseJSON(response) {
		var contentType = response.headers.get('content-type');
		if (contentType && contentType.includes('application/json')) {
			return response.text().then(function(text) {
				return text ? JSON.parse(text) : {};
			});
		}
		return Promise.resolve({});
	}

	/**
	 * Normalize error response to consistent format
	 */
	function normalizeError(error, response) {
		return {
			success: false,
			status: response ? response.status : 0,
			error: error.message || error.error || 'An error occurred',
			details: error.details || error.errors || null,
			response: response
		};
	}

	// ============================================
	// CORE API OBJECT
	// ============================================

	var Api = {
		config: config,

		/**
		 * Base request method - all API calls go through here
		 * 
		 * @param {string} url - API endpoint
		 * @param {Object} options - Fetch options
		 * @param {string} options.method - HTTP method (default: GET)
		 * @param {Object} options.body - Request body (will be JSON stringified)
		 * @param {Object} options.headers - Additional headers
		 * @param {number} options.timeout - Request timeout in ms
		 * @param {boolean} options.retry - Enable retry for 503 (default: true for GET)
		 * @param {boolean} options.dedupe - Enable deduplication (default: true for GET)
		 * @param {AbortSignal} options.signal - External abort signal
		 * @returns {Promise<Object>} Parsed JSON response
		 */
		request: function(url, options) {
			options = options || {};
			var method = (options.method || 'GET').toUpperCase();
			var timeout = options.timeout || config.timeout;
			var shouldRetry = options.retry !== undefined ? options.retry : (method === 'GET');
			var shouldDedupe = options.dedupe !== undefined ? options.dedupe : (config.deduplicateGET && method === 'GET');

			var requestKey = getRequestKey(url, method);

			// Check for duplicate in-flight request
			if (shouldDedupe && pendingRequests[requestKey]) {
				console.log('[Funky.Api] Deduplicating request:', requestKey);
				return pendingRequests[requestKey].promise;
			}

			// Create abort controller for timeout and SPA cancellation
			var controller = new AbortController();
			activeControllers.add(controller);

			// Merge external signal if provided
			if (options.signal) {
				options.signal.addEventListener('abort', function() {
					controller.abort();
				});
			}

			// Set up timeout
			var timeoutId = setTimeout(function() {
				controller.abort();
			}, timeout);

			// Build fetch options
			var fetchOptions = {
				method: method,
				headers: Object.assign({}, options.headers || {}),
				signal: controller.signal
			};

			// Add CSRF token for mutating requests
			if (['POST', 'PUT', 'DELETE', 'PATCH'].includes(method)) {
				var csrfToken = getCsrfToken();
				if (!csrfToken) {
					console.error('[Funky.Api] CSRF token not found');
					return Promise.reject(normalizeError({ message: 'CSRF token missing' }, null));
				}
				fetchOptions.headers['X-CSRF-Token'] = csrfToken;
			}

			// Add body for non-GET requests
			if (options.body && method !== 'GET') {
				if (options.body instanceof FormData) {
					// FormData - don't set Content-Type, browser will set it with boundary
					fetchOptions.body = options.body;
				} else {
					fetchOptions.headers['Content-Type'] = 'application/json';
					fetchOptions.body = JSON.stringify(options.body);
				}
			}

			// Emit request event
			if (Funky.PubSub) {
				Funky.PubSub.emit('funky:api:request', { url: url, method: method, options: options });
			}

			// Execute request with retry logic
			var executeRequest = function(attempt) {
				return fetch(url, fetchOptions)
					.then(function(response) {
						clearTimeout(timeoutId);
						activeControllers.delete(controller);

						// Handle different status codes
						if (response.ok) {
							return parseJSON(response).then(function(data) {
								// Emit success event
								if (Funky.PubSub) {
									Funky.PubSub.emit('funky:api:success', { url: url, method: method, data: data });
								}
								return data;
							});
						}

						// Handle errors
						return parseJSON(response).then(function(errorData) {
							var error = normalizeError(errorData, response);

							// Retry on 503 if enabled
							if (response.status === 503 && shouldRetry && attempt < config.maxRetries) {
								var delay = config.retryDelay * Math.pow(2, attempt - 1);
								console.log('[Funky.Api] Retrying in', delay, 'ms (attempt', attempt + 1, ')');
								return sleep(delay).then(function() {
									return executeRequest(attempt + 1);
								});
							}

							// Handle specific status codes
							Api.handleError(error);

							throw error;
						});
					})
					.catch(function(error) {
						clearTimeout(timeoutId);
						activeControllers.delete(controller);
						delete pendingRequests[requestKey];

						// Handle abort (timeout or SPA navigation)
						if (error.name === 'AbortError') {
							var abortError = normalizeError({ message: 'Request cancelled' }, null);
							abortError.aborted = true;
							throw abortError;
						}

						// Emit error event
						if (Funky.PubSub) {
							Funky.PubSub.emit('funky:api:error', { url: url, method: method, error: error });
						}

						throw error;
					});
			};

			// Start request
			var promise = executeRequest(1).finally(function() {
				delete pendingRequests[requestKey];
			});

			// Store for deduplication
			if (shouldDedupe) {
				pendingRequests[requestKey] = {
					promise: promise,
					controller: controller
				};
			}

			return promise;
		},

		/**
		 * Global error handler - can be overridden
		 */
		handleError: function(error) {
			if (error.status === 401) {
				// Session expired
				if (Funky.PubSub) {
					Funky.PubSub.emit('funky:session:expired', { error: error });
				}
				console.warn('[Funky.Api] Session expired');
			} else if (error.status === 403) {
				// Permission denied
				if (Funky.Toast) {
					Funky.Toast.error('Permission denied');
				}
			} else if (error.status === 422) {
				// Validation error - caller should handle
				// Don't show toast, let caller display field errors
			} else if (error.status === 429) {
				// Rate limited
				if (Funky.Toast) {
					Funky.Toast.warning('Too many requests. Please slow down.');
				}
			} else if (error.status >= 500) {
				// Server error
				if (Funky.Toast) {
					Funky.Toast.error('Server error. Please try again later.');
				}
			}

			// Emit error event
			if (Funky.PubSub) {
				Funky.PubSub.emit('funky:api:error', { status: error.status, error: error });
			}
		},

		// ============================================
		// CONVENIENCE METHODS
		// ============================================

		/**
		 * GET request
		 * @param {string} url - API endpoint
		 * @param {Object} params - Query parameters
		 * @param {Object} options - Additional options
		 */
		get: function(url, params, options) {
			// Build URL with query params
			if (params && Object.keys(params).length > 0) {
				var queryString = new URLSearchParams(params).toString();
				url = url + (url.includes('?') ? '&' : '?') + queryString;
			}
			return Api.request(url, Object.assign({ method: 'GET' }, options || {}));
		},

		/**
		 * POST request
		 * @param {string} url - API endpoint
		 * @param {Object} data - Request body
		 * @param {Object} options - Additional options
		 */
		post: function(url, data, options) {
			return Api.request(url, Object.assign({ method: 'POST', body: data }, options || {}));
		},

		/**
		 * PUT request
		 * @param {string} url - API endpoint
		 * @param {Object} data - Request body
		 * @param {Object} options - Additional options
		 */
		put: function(url, data, options) {
			return Api.request(url, Object.assign({ method: 'PUT', body: data }, options || {}));
		},

		/**
		 * PATCH request
		 * @param {string} url - API endpoint
		 * @param {Object} data - Request body
		 * @param {Object} options - Additional options
		 */
		patch: function(url, data, options) {
			return Api.request(url, Object.assign({ method: 'PATCH', body: data }, options || {}));
		},

		/**
		 * DELETE request
		 * @param {string} url - API endpoint
		 * @param {Object} options - Additional options
		 */
		delete: function(url, options) {
			return Api.request(url, Object.assign({ method: 'DELETE' }, options || {}));
		},

		/**
		 * Fetch (alias for GET with JSON response handling)
		 * For compatibility with code expecting fetch-style API
		 * @param {string} url - API endpoint
		 * @param {Object} options - Fetch-style options
		 */
		fetch: function(url, options) {
			options = options || {};
			var method = (options.method || 'GET').toUpperCase();

			if (method === 'GET') {
				return Api.get(url);
			} else if (method === 'POST') {
				var body = options.body;
				if (typeof body === 'string') {
					try { body = JSON.parse(body); } catch (e) {}
				}
				return Api.post(url, body);
			} else if (method === 'PUT') {
				var putBody = options.body;
				if (typeof putBody === 'string') {
					try { putBody = JSON.parse(putBody); } catch (e) {}
				}
				return Api.put(url, putBody);
			} else if (method === 'DELETE') {
				return Api.delete(url);
			}
			return Api.request(url, options);
		},

		// ============================================
		// FILE UPLOAD
		// ============================================

		/**
		 * Upload file(s) with progress tracking
		 * @param {string} url - Upload endpoint
		 * @param {FormData} formData - Form data with files
		 * @param {Function} onProgress - Progress callback (receives { loaded, total, percent })
		 * @param {Object} options - Additional options
		 * @returns {Promise<Object>}
		 */
		upload: function(url, formData, onProgress, options) {
			options = options || {};

			return new Promise(function(resolve, reject) {
				var xhr = new XMLHttpRequest();

				// Track this request for SPA cancellation
				var controller = {
					abort: function() { xhr.abort(); }
				};
				activeControllers.add(controller);

				// Progress handler
				if (onProgress && xhr.upload) {
					xhr.upload.addEventListener('progress', function(e) {
						if (e.lengthComputable) {
							onProgress({
								loaded: e.loaded,
								total: e.total,
								percent: Math.round((e.loaded / e.total) * 100)
							});
						}
					});
				}

				// Completion handler
				xhr.addEventListener('load', function() {
					activeControllers.delete(controller);

					var response;
					try {
						response = JSON.parse(xhr.responseText);
					} catch (e) {
						response = { error: 'Invalid response' };
					}

					if (xhr.status >= 200 && xhr.status < 300) {
						if (Funky.PubSub) {
							Funky.PubSub.emit('funky:api:success', { url: url, method: 'POST', data: response });
						}
						resolve(response);
					} else {
						var error = normalizeError(response, { status: xhr.status });
						Api.handleError(error);
						reject(error);
					}
				});

				// Error handler
				xhr.addEventListener('error', function() {
					activeControllers.delete(controller);
					var error = normalizeError({ message: 'Upload failed' }, null);
					reject(error);
				});

				// Abort handler
				xhr.addEventListener('abort', function() {
					activeControllers.delete(controller);
					var error = normalizeError({ message: 'Upload cancelled' }, null);
					error.aborted = true;
					reject(error);
				});

				// Open and send
				xhr.open('POST', url, true);

				// Add CSRF token
				var csrfToken = getCsrfToken();
				if (csrfToken) {
					xhr.setRequestHeader('X-CSRF-Token', csrfToken);
				}

				// Emit request event
				if (Funky.PubSub) {
					Funky.PubSub.emit('funky:api:request', { url: url, method: 'POST', upload: true });
				}

				xhr.send(formData);
			});
		},

		// ============================================
		// PAGINATED FETCH
		// ============================================

		/**
		 * Fetch all records from a paginated API endpoint
		 * @param {string} url - API endpoint
		 * @param {Object} options - Options
		 * @param {Object} options.params - Query parameters
		 * @param {Function} options.onProgress - Progress callback
		 * @param {number} options.maxPages - Maximum pages to fetch (default: 100)
		 * @param {number} options.limit - Records per page (default: 100)
		 * @returns {Promise<Array>} All items
		 */
		fetchAll: function(url, options) {
			options = options || {};
			var params = options.params || {};
			var onProgress = options.onProgress;
			var maxPages = options.maxPages || 100;
			var limit = options.limit || 100;

			var allItems = [];
			var currentPage = 1;
			var totalPages = 1;

			var fetchPage = function(page) {
				var queryParams = Object.assign({}, params, {
					page: page,
					limit: limit
				});

				return Api.get(url, queryParams, { dedupe: false }).then(function(data) {
					// Handle different response formats
					var items = [];
					var total = 0;

					if (data.data && Array.isArray(data.data)) {
						items = data.data;
						total = data.total || data.count || items.length;
					} else if (Array.isArray(data)) {
						items = data;
						total = items.length;
					} else {
						// Find array in response
						var keys = Object.keys(data);
						for (var i = 0; i < keys.length; i++) {
							if (Array.isArray(data[keys[i]])) {
								items = data[keys[i]];
								total = data.total || data.count || items.length;
								break;
							}
						}
					}

					allItems = allItems.concat(items);

					// Calculate total pages
					if (total > 0) {
						totalPages = Math.ceil(total / limit);
					}

					// Progress callback
					if (onProgress && typeof onProgress === 'function') {
						onProgress({
							page: page,
							totalPages: totalPages,
							itemsInPage: items.length,
							totalItems: allItems.length,
							expectedTotal: total
						});
					}

					// Fetch more if needed
					if (page < totalPages && page < maxPages && items.length === limit) {
						return fetchPage(page + 1);
					}

					return allItems;
				});
			};

			return fetchPage(1);
		},

		// ============================================
		// ENTITY FACTORY
		// ============================================

		/**
		 * Create CRUD methods for an entity
		 * @param {string} entityName - Entity name (for import endpoint)
		 * @param {string} baseUrl - Base API URL
		 * @returns {Object} Entity API object
		 */
		entity: function(entityName, baseUrl) {
			return {
				/**
				 * List all records
				 */
				list: function(params) {
					return Api.get(baseUrl, params);
				},

				/**
				 * Fetch all records (paginated)
				 */
				fetchAll: function(options) {
					return Api.fetchAll(baseUrl, options);
				},

				/**
				 * Get single record by ID
				 */
				get: function(id) {
					return Api.get(baseUrl + '/' + id);
				},

				/**
				 * Create new record
				 */
				create: function(data) {
					return Api.post(baseUrl, data);
				},

				/**
				 * Update record by ID
				 */
				update: function(id, data) {
					return Api.put(baseUrl + '/' + id, data);
				},

				/**
				 * Partially update record by ID
				 */
				patch: function(id, data) {
					return Api.patch(baseUrl + '/' + id, data);
				},

				/**
				 * Delete record by ID
				 */
				delete: function(id) {
					return Api.delete(baseUrl + '/' + id);
				},

				/**
				 * Import records from file
				 */
				import: function(formData, onProgress) {
					return Api.upload('/api/import/csv/' + entityName, formData, onProgress);
				}
			};
		},

		// ============================================
		// SPA INTEGRATION
		// ============================================

		/**
		 * Cancel all pending requests (called on SPA navigation)
		 */
		cancelAll: function() {
			var count = activeControllers.size;
			activeControllers.forEach(function(controller) {
				try {
					controller.abort();
				} catch (e) {
					// Ignore
				}
			});
			activeControllers.clear();
			pendingRequests = {};

			if (count > 0) {
				console.log('[Funky.Api] Cancelled', count, 'pending requests');
			}
		}
	};

	// ============================================
	// PRE-REGISTERED ENTITIES
	// ============================================

	Api.clients = Api.entity('clients', '/api/clients');
	Api.trades = Api.entity('trades', '/api/trades');
	Api.securities = Api.entity('securities', '/api/securities');
	Api.allocations = Api.entity('allocations', '/api/allocations');
	Api.users = Api.entity('users', '/api/users');
	Api.fxRates = Api.entity('fx_rates', '/api/fx_rates');
	Api.tradeActions = Api.entity('trade_actions', '/api/trade_actions');
	Api.reportFormats = Api.entity('report_formats', '/api/report_formats');
	Api.clientRelationships = Api.entity('client_relationships', '/api/client_relationships');
	Api.savedFilters = Api.entity('saved_filters', '/api/saved_filters');
	Api.pushSubscriptions = Api.entity('push_subscriptions', '/api/push/subscriptions');
	Api.pushNotifications = Api.entity('push_notifications', '/api/push/notifications');

	// ============================================
	// CONVENIENCE WRAPPERS (for backwards compatibility)
	// ============================================

	Api.fetchAllClients = function(options) { return Api.clients.fetchAll(options); };
	Api.fetchAllSecurities = function(options) { return Api.securities.fetchAll(options); };
	Api.fetchAllAllocations = function(options) { return Api.allocations.fetchAll(options); };
	Api.fetchAllUsers = function(options) { return Api.users.fetchAll(options); };
	Api.fetchAllTrades = function(options) { return Api.trades.fetchAll(options); };
	Api.fetchAllClientRelationships = function(options) { return Api.clientRelationships.fetchAll(options); };
	Api.fetchAllFxRates = function(options) { return Api.fxRates.fetchAll(options); };
	Api.fetchAllTradeActions = function(options) { return Api.tradeActions.fetchAll(options); };
	Api.fetchAllReportFormats = function(options) { return Api.reportFormats.fetchAll(options); };

	// ============================================
	// REGISTER WITH FUNKY NAMESPACE
	// ============================================

	Funky.register('Api', Api);

	// Listen for SPA navigation to cancel requests
	document.addEventListener('funky.spa.before-load', function() {
		Api.cancelAll();
	});

})(window);

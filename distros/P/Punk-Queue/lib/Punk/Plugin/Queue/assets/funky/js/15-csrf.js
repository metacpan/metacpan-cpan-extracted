/**
 * CSRF Protection Utilities
 * Handles CSRF token management for API requests
 * @module Funky.CSRF
 * @version 1.0.4
 */
(function(window) {
	'use strict';

	// Registry guard - prevent double registration
	if (typeof Funky !== 'undefined' && Funky.isRegistered && Funky.isRegistered('CSRF')) {
		return;
	}

	/**
	 * CSRF utility object
	 */
	var CSRF = {
		/**
		 * Get CSRF token from cookie
		 * @returns {string|null} The CSRF token or null if not found
		 */
		getToken: function() {
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
		},

		/**
		 * Enhanced fetch wrapper with automatic CSRF token injection
		 * @param {string} url - The URL to fetch
		 * @param {Object} options - Fetch options
		 * @returns {Promise} Fetch promise
		 */
		secureFetch: function(url, options) {
			// Guard against missing URL
			if (!url || typeof url !== 'string') {
				return Promise.reject(new Error('URL is required'));
			}
			options = options || {};

			// Clone options to avoid mutating original
			var fetchOptions = Object.assign({}, options);

			// Only add CSRF token for state-changing methods
			var method = (fetchOptions.method || 'GET').toUpperCase();
			if (['POST', 'PUT', 'DELETE', 'PATCH'].indexOf(method) !== -1) {
				var csrfToken = this.getToken();

				if (!csrfToken) {
					console.error('CSRF token not found. User may need to log in again.');
					return Promise.reject(new Error('CSRF token missing'));
				}

				// Clone headers to avoid mutating original options.headers
				fetchOptions.headers = Object.assign({}, options.headers || {});

				// Add CSRF token to headers
				fetchOptions.headers['X-CSRF-Token'] = csrfToken;
			}

			var self = this;

			// Make the fetch request
			return fetch(url, fetchOptions)
				.then(function(response) {
					// If we get a 403 with CSRF error, the token might be expired
					if (response.status === 403) {
						return response.json().then(function(data) {
							if (data.error && data.error.indexOf('CSRF') !== -1) {
								console.error('CSRF token validation failed. Redirecting to login...');
								// Optionally redirect to login
								// window.location.href = '/auth/login';
							}
							throw new Error(data.error || 'Forbidden');
						});
					}
					return response;
				});
		},

		/**
		 * Store CSRF token from login response
		 * Token is automatically stored as cookie by server
		 * @param {string} token - The CSRF token
		 */
		storeToken: function(token) {
			// Token is automatically stored as cookie by server
			// This function is here for consistency and future use
			console.log('CSRF token received and stored');
		}
	};

	// Register with Funky
	if (typeof Funky !== 'undefined' && Funky.register) {
		Funky.register('CSRF', CSRF);
	}

})(window);

/**
 * Funky Keyboard - Centralized Shortcut Manager
 * 
 * Features:
 * - Global shortcut registry
 * - Scope-based activation
 * - Platform-aware (mod = ⌘/Ctrl)
 * - Conflict resolution
 * - Help overlay (F1)
 * 
 * No jQuery - Pure vanilla JavaScript
 * 
 * @module Funky.Keyboard
 * @version 1.0.4
 */
(function(window) {
  'use strict';

  // Registry guard
  if (typeof Funky !== 'undefined' && Funky.isRegistered && Funky.isRegistered('Keyboard')) {
    return;
  }

  // ==========================================================================
  // CONSTANTS
  // ==========================================================================

  var isMac = /Mac|iPod|iPhone|iPad/.test(navigator.platform);

  var KEY_CODES = {
    8: 'backspace',
    9: 'tab',
    13: 'enter',
    27: 'escape',
    32: 'space',
    33: 'pageup',
    34: 'pagedown',
    35: 'end',
    36: 'home',
    37: 'left',
    38: 'up',
    39: 'right',
    40: 'down',
    46: 'delete',
    112: 'f1',
    113: 'f2',
    114: 'f3',
    115: 'f4',
    116: 'f5',
    117: 'f6',
    118: 'f7',
    119: 'f8',
    120: 'f9',
    121: 'f10',
    122: 'f11',
    123: 'f12',
    186: ';',
    187: '=',
    188: ',',
    189: '-',
    190: '.',
    191: '/',
    192: '`',
    219: '[',
    220: '\\',
    221: ']',
    222: "'"
  };

  // ==========================================================================
  // STATE
  // ==========================================================================

  var shortcuts = [];           // Array of registered shortcuts
  var shortcutIdCounter = 0;    // Unique ID generator
  var scopeStack = ['global'];  // Scope stack, global is always base
  var scopeContexts = {};       // { scopeName: contextObject }
  var helpVisible = false;
  var helpOverlay = null;
  var helpShowActiveOnly = false;  // Filter to show only active shortcuts

  // ==========================================================================
  // KEY PARSING
  // ==========================================================================

  /**
   * Get key name from keyboard event
   * @param {KeyboardEvent} e
   * @returns {string}
   */
  function getKeyFromEvent(e) {
    // On macOS, Option/Alt key produces special characters or dead keys
    // Use e.code to get the physical key when Alt is pressed
    if (e.altKey && e.code) {
      // Handle letter keys (KeyA -> a, KeyN -> n, etc.)
      if (e.code.indexOf('Key') === 0 && e.code.length === 4) {
        return e.code.charAt(3).toLowerCase();
      }
      // Handle digit keys (Digit1 -> 1, etc.)
      if (e.code.indexOf('Digit') === 0 && e.code.length === 6) {
        return e.code.charAt(5);
      }
      // Handle special keys via code
      var codeMap = {
        'Backspace': 'backspace',
        'Tab': 'tab',
        'Enter': 'enter',
        'Escape': 'escape',
        'Space': 'space',
        'ArrowUp': 'up',
        'ArrowDown': 'down',
        'ArrowLeft': 'left',
        'ArrowRight': 'right',
        'Delete': 'delete',
        'Home': 'home',
        'End': 'end',
        'PageUp': 'pageup',
        'PageDown': 'pagedown',
        'Semicolon': ';',
        'Equal': '=',
        'Comma': ',',
        'Minus': '-',
        'Period': '.',
        'Slash': '/',
        'Backquote': '`',
        'BracketLeft': '[',
        'Backslash': '\\',
        'BracketRight': ']',
        'Quote': "'"
      };
      if (codeMap[e.code]) {
        return codeMap[e.code];
      }
      // Handle F-keys
      if (e.code.indexOf('F') === 0 && e.code.length <= 3) {
        return e.code.toLowerCase();
      }
    }

    // Prefer e.key (modern) over e.keyCode (deprecated)
    // Normalize special key names for consistency
    if (e.key) {
      var key = e.key.toLowerCase();
      // Handle arrow keys (ArrowUp -> up, etc.)
      if (key.indexOf('arrow') === 0) {
        return key.replace('arrow', '');
      }
      // Normalize space key
      if (key === ' ') {
        return 'space';
      }
      return key;
    }

    // Fallback to keyCode for older browsers
    if (KEY_CODES[e.keyCode]) {
      return KEY_CODES[e.keyCode];
    }

    // Letter keys (A-Z)
    if (e.keyCode >= 65 && e.keyCode <= 90) {
      return String.fromCharCode(e.keyCode).toLowerCase();
    }

    // Number keys (0-9)
    if (e.keyCode >= 48 && e.keyCode <= 57) {
      return String.fromCharCode(e.keyCode);
    }

    // Numpad (0-9)
    if (e.keyCode >= 96 && e.keyCode <= 105) {
      return 'numpad' + (e.keyCode - 96);
    }

    return '';
  }

  /**
   * Normalize arrow key names for consistent matching
   * Handles both forms: 'arrowup'/'arrowdown'/etc and 'up'/'down'/etc
   * @param {string} key
   * @returns {string} Normalized key (without 'arrow' prefix)
   */
  function normalizeArrowKey(key) {
    if (!key) return key;
    // Remove 'arrow' prefix if present for consistent matching
    if (key.indexOf('arrow') === 0) {
      return key.substring(5); // 'arrowup' -> 'up'
    }
    return key;
  }

  /**
   * Check if event matches shortcut definition
   * @param {Object} shortcut - Shortcut definition
   * @param {KeyboardEvent} e
   * @returns {boolean}
   */
  function matchesEvent(shortcut, e) {
    var key = getKeyFromEvent(e);

    // Key must match (normalize arrow keys to handle both 'up' and 'arrowup' forms)
    if (!shortcut.key) {
      return false;
    }
    var shortcutKey = normalizeArrowKey(shortcut.key.toLowerCase());
    var eventKey = normalizeArrowKey(key);
    if (eventKey !== shortcutKey) {
      return false;
    }

    // Check mod (platform-aware)
    var modKey = isMac ? e.metaKey : e.ctrlKey;

    if (shortcut.mod && !modKey) return false;
    if (!shortcut.mod && modKey && !shortcut.ctrl && !shortcut.meta) return false;

    // Check explicit modifiers
    if (shortcut.ctrl && !e.ctrlKey) return false;
    if (shortcut.alt && !e.altKey) return false;
    if (shortcut.shift && !e.shiftKey) return false;
    if (shortcut.meta && !e.metaKey) return false;

    // Check for unwanted modifiers
    if (!shortcut.alt && e.altKey) return false;
    if (!shortcut.shift && e.shiftKey) return false;

    return true;
  }

  // ==========================================================================
  // SCOPE MANAGEMENT
  // ==========================================================================

  /**
   * Get current active scope
   * @returns {string}
   */
  function getCurrentScope() {
    return scopeStack[scopeStack.length - 1];
  }

  /**
   * Check if a scope is in the stack
   * @param {string} scope
   * @returns {boolean}
   */
  function hasScope(scope) {
    if (scope === 'global') return true;
    return scopeStack.indexOf(scope) !== -1;
  }

  /**
   * Push a new scope onto the stack
   * @param {string} scope - Scope name
   * @param {Object} context - Context object for `this` binding
   */
  function pushScope(scope, context) {
    scopeStack.push(scope);
    if (context) {
      scopeContexts[scope] = context;
    }
    
    // Emit event
    document.dispatchEvent(new CustomEvent('funky.keyboard.scope-push', {
      detail: { scope: scope, stack: scopeStack.slice() }
    }));
  }

  /**
   * Pop the current scope from the stack
   * @returns {string|null} Popped scope name
   */
  function popScope() {
    if (scopeStack.length > 1) {
      var scope = scopeStack.pop();
      delete scopeContexts[scope];
      
      // Emit event
      document.dispatchEvent(new CustomEvent('funky.keyboard.scope-pop', {
        detail: { scope: scope, stack: scopeStack.slice() }
      }));
      
      return scope;
    }
    return null;
  }

  /**
   * Replace current scope (pop then push)
   * @param {string} scope
   * @param {Object} context
   */
  function replaceScope(scope, context) {
    if (scopeStack.length > 1) {
      var oldScope = scopeStack.pop();
      delete scopeContexts[oldScope];
    }
    pushScope(scope, context);
  }

  /**
   * Clear all scopes except global
   */
  function clearScopes() {
    while (scopeStack.length > 1) {
      var scope = scopeStack.pop();
      delete scopeContexts[scope];
    }
  }

  /**
   * Get all active scopes
   * @returns {Array<string>}
   */
  function getActiveScopes() {
    return scopeStack.slice();
  }

  /**
   * Check if shortcut scope is currently active
   * @param {string} shortcutScope
   * @returns {boolean}
   */
  function isInScope(shortcutScope) {
    // Global is always active
    if (shortcutScope === 'global') {
      return true;
    }
    
    // Element scope - check if element or child is focused
    if (shortcutScope.charAt(0) === '#') {
      var element = document.querySelector(shortcutScope);
      if (!element) return false;
      
      return element === document.activeElement ||
             element.contains(document.activeElement);
    }
    
    // Named scope - must be in stack
    return scopeStack.indexOf(shortcutScope) !== -1;
  }

  /**
   * Get scope context for `this` binding
   * @param {string} scope
   * @returns {Object|null}
   */
  function getScopeContext(scope) {
    return scopeContexts[scope] || null;
  }

  // ==========================================================================
  // REGISTRATION
  // ==========================================================================

  /**
   * Register a keyboard shortcut
   * @param {Object} options - Shortcut configuration
   * @returns {Function} Unregister function
   */
  function register(options) {
    // Ensure initialized (listener attached)
    if (!_keydownListenerAdded) {
      init();
    }

    // Handle null/undefined options
    if (!options) {
      console.error('[Funky.Keyboard] register: options is required');
      return function() {};
    }
    // Validate required fields
    if (!options.key) {
      console.error('[Funky.Keyboard] register: key is required');
      return function() {};
    }
    if (typeof options.handler !== 'function') {
      console.error('[Funky.Keyboard] register: handler must be a function');
      return function() {};
    }

    var shortcut = {
      id: ++shortcutIdCounter,
      key: options.key.toLowerCase(),
      mod: !!options.mod,
      ctrl: !!options.ctrl,
      alt: !!options.alt,
      shift: !!options.shift,
      meta: !!options.meta,
      handler: options.handler,
      scope: options.scope || 'global',
      context: options.context || null,
      description: options.description || '',
      group: options.group || 'General',
      preventDefault: options.preventDefault !== false,
      stopPropagation: !!options.stopPropagation,
      allowInInput: !!options.allowInInput,
      priority: options.priority || 0
    };

    shortcuts.push(shortcut);

    // Sort by priority (higher first)
    shortcuts.sort(function(a, b) {
      return b.priority - a.priority;
    });

    // Return unregister function
    return function unregister() {
      var index = -1;
      for (var i = 0; i < shortcuts.length; i++) {
        if (shortcuts[i].id === shortcut.id) {
          index = i;
          break;
        }
      }
      if (index !== -1) {
        shortcuts.splice(index, 1);
      }
    };
  }

  /**
   * Unregister all shortcuts for a scope
   * @param {string} scope
   */
  function unregisterScope(scope) {
    shortcuts = shortcuts.filter(function(s) {
      return s.scope !== scope;
    });
  }

  /**
   * Unregister all shortcuts for a group
   * @param {string} group
   */
  function unregisterGroup(group) {
    shortcuts = shortcuts.filter(function(s) {
      return s.group !== group;
    });
  }

  // ==========================================================================
  // EVENT HANDLING
  // ==========================================================================

  /**
   * Main keydown event handler
   * @param {KeyboardEvent} e
   */
  function handleKeydown(e) {
    var key = getKeyFromEvent(e);

    // Skip if in input (unless shortcut allows it)
    var target = e.target;
    var isInput = target.tagName === 'INPUT' ||
                  target.tagName === 'TEXTAREA' ||
                  target.isContentEditable;

    // Check shortcuts in priority order
    for (var i = 0; i < shortcuts.length; i++) {
      var shortcut = shortcuts[i];

      // Skip if doesn't match key combo
      if (!matchesEvent(shortcut, e)) {
        continue;
      }

      // Skip if in input and not allowed
      // Shortcuts with ctrl/meta modifiers work in inputs by default (like ctrl+k)
      var hasModifier = shortcut.ctrl || shortcut.meta || shortcut.mod;
      if (isInput && !shortcut.allowInInput && !hasModifier) {
        continue;
      }

      // Skip if not in scope
      if (!isInScope(shortcut.scope)) {
        continue;
      }

      // Execute handler
      if (shortcut.preventDefault) {
        e.preventDefault();
      }
      if (shortcut.stopPropagation) {
        e.stopPropagation();
      }

      // Get context for `this` binding
      var context = shortcut.context || getScopeContext(shortcut.scope) || window;

      try {
        shortcut.handler.call(context, e);
      } catch (error) {
        console.error('[Funky.Keyboard] Handler error:', error);
      }

      // First matching shortcut wins
      break;
    }
  }

  // ==========================================================================
  // UTILITIES
  // ==========================================================================

  /**
   * Format shortcut for display
   * @param {Object} shortcut
   * @returns {string}
   */
  function formatShortcut(shortcut) {
    var parts = [];
    
    if (shortcut.mod) {
      parts.push(isMac ? '⌘' : 'Ctrl');
    }
    if (shortcut.ctrl) {
      parts.push(isMac ? '⌃' : 'Ctrl');
    }
    if (shortcut.alt) {
      parts.push(isMac ? '⌥' : 'Alt');
    }
    if (shortcut.shift) {
      parts.push(isMac ? '⇧' : 'Shift');
    }
    if (shortcut.meta) {
      parts.push(isMac ? '⌘' : 'Win');
    }

    // Format key (normalize arrow keys to handle both 'up' and 'arrowup' forms)
    var keyLower = normalizeArrowKey(shortcut.key.toLowerCase());
    var key = shortcut.key.toUpperCase();
    switch(keyLower) {
      case 'escape': key = 'Esc'; break;
      case 'enter': key = '↵'; break;
      case 'space': key = 'Space'; break;
      case 'up': key = '↑'; break;
      case 'down': key = '↓'; break;
      case 'left': key = '←'; break;
      case 'right': key = '→'; break;
      case 'backspace': key = '⌫'; break;
      case 'delete': key = 'Del'; break;
      case 'tab': key = 'Tab'; break;
    }
    
    parts.push(key);
    
    return parts.join(isMac ? '' : '+');
  }

  /**
   * Get all registered shortcuts
   * @param {Object} filter - Optional filter { scope, group, activeOnly }
   * @returns {Array}
   */
  function getShortcuts(filter) {
    var result = shortcuts;
    
    if (filter) {
      if (filter.scope) {
        result = result.filter(function(s) {
          return s.scope === filter.scope;
        });
      }
      if (filter.group) {
        result = result.filter(function(s) {
          return s.group === filter.group;
        });
      }
      if (filter.activeOnly) {
        result = result.filter(function(s) {
          return isInScope(s.scope);
        });
      }
    }
    
    return result;
  }

  /**
   * Escape HTML entities
   * @param {string} text
   * @returns {string}
   */
  function escapeHtml(text) {
    var div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }

  // ==========================================================================
  // HELP OVERLAY
  // ==========================================================================

  /**
   * Show help overlay
   */
  function showHelp() {
    if (helpVisible) return;
    
    // Create overlay
    helpOverlay = document.createElement('div');
    helpOverlay.className = 'funky-keyboard-help';
    helpOverlay.setAttribute('role', 'dialog');
    helpOverlay.setAttribute('aria-modal', 'true');
    helpOverlay.setAttribute('aria-label', 'Keyboard shortcuts');
    
    // Build content using Funky.VDom
    var content = buildHelpContent();
    helpOverlay.appendChild(Funky.VDom.render(content));
    
    document.body.appendChild(helpOverlay);
    
    // Focus close button
    var closeBtn = helpOverlay.querySelector('.fkh-close');
    if (closeBtn) {
      closeBtn.focus();
      closeBtn.addEventListener('click', hideHelp);
    }
    
    // Close on backdrop click
    helpOverlay.addEventListener('click', function(e) {
      if (e.target === helpOverlay) hideHelp();
    });
    
    // Setup search filter
    setupHelpSearch();

    // Setup interactive shortcut buttons
    setupShortcutButtons();

    // Push help scope
    pushScope('keyboard-help');

    helpVisible = true;

    // Emit event
    document.dispatchEvent(new CustomEvent('funky.keyboard.help-show'));
  }

  /**
   * Hide help overlay
   */
  function hideHelp() {
    if (!helpVisible || !helpOverlay) return;
    
    helpOverlay.classList.add('fkh--closing');
    
    setTimeout(function() {
      if (helpOverlay && helpOverlay.parentNode) {
        helpOverlay.parentNode.removeChild(helpOverlay);
        helpOverlay = null;
      }
    }, 150);
    
    popScope();
    helpVisible = false;
    
    // Emit event
    document.dispatchEvent(new CustomEvent('funky.keyboard.help-hide'));
  }

  /**
   * Toggle help overlay
   */
  function toggleHelp() {
    if (helpVisible) {
      hideHelp();
    } else {
      showHelp();
    }
  }

  /**
   * Build help overlay content using Funky.VDom
   * @returns {VNode}
   */
  function buildHelpContent() {
    var V = Funky.VDom;
    
    // Group shortcuts by group name
    var groups = {};
    
    for (var i = 0; i < shortcuts.length; i++) {
      var shortcut = shortcuts[i];
      
      // Only show shortcuts with descriptions
      if (!shortcut.description) continue;
      
      var group = shortcut.group;
      if (!groups[group]) {
        groups[group] = { shortcuts: [], active: false };
      }
      
      // Check if this group's scope is active
      if (isInScope(shortcut.scope)) {
        groups[group].active = true;
      }
      
      groups[group].shortcuts.push({
        key: formatShortcut(shortcut),
        description: shortcut.description,
        scope: shortcut.scope,
        shortcut: shortcut  // Store reference to original shortcut
      });
    }
    
    // Sort groups alphabetically, but put 'Help' first and 'General' second
    var groupNames = Object.keys(groups).sort(function(a, b) {
      if (a === 'Help') return -1;
      if (b === 'Help') return 1;
      if (a === 'General') return -1;
      if (b === 'General') return 1;
      return a.localeCompare(b);
    });
    
    return V.div().class('fkh-dialog').child(
      // Header
      V.div().class('fkh-header').child(
        V.h2().child(
          V.icon('fas fa-keyboard'),
          ' Keyboard Shortcuts'
        ),
        V.button()
          .class('fkh-close')
          .aria('label', 'Close')
          .text('×')
      ),
      
      // Search bar
      V.div().class('fkh-search').child(
        V.input()
          .class('fkh-search-input')
          .attr('type', 'text')
          .attr('placeholder', 'Search shortcuts...')
          .aria('label', 'Search shortcuts')
      ),
      
      // Content
      V.div().class('fkh-content').child(
        // Shortcut groups
        groupNames.length > 0 
          ? V.each(groupNames, function(groupName) {
              var groupData = groups[groupName];
              return V.div()
                .class(V.classes('fkh-group', groupData.active && 'fkh-group--active'))
                .data('group', groupName)
                .child(
                  // Group header
                  V.h3().child(
                    groupName,
                    groupData.active && V.span().class('fkh-active-badge').text(' Active')
                  ),
                  // Shortcut list
                  V.ul().child(
                    V.each(groupData.shortcuts, function(item) {
                      return V.li()
                        .data('key', item.key.toLowerCase())
                        .data('desc', item.description.toLowerCase())
                        .child(
                          V.button()
                            .class('fkh-shortcut-btn')
                            .attr('type', 'button')
                            .attr('tabindex', '0')
                            .data('shortcut-id', item.shortcut.id)
                            .child(
                              V.kbd().text(item.key),
                              V.span().text(item.description)
                            )
                        );
                    })
                  )
                );
            })
          // Empty state
          : V.div().class('fkh-empty').child(
              V.icon('fas fa-keyboard'),
              V.p().text('No keyboard shortcuts registered')
            ),
        
        // No results (hidden by default)
        V.div().class('fkh-no-results').style({ display: 'none' }).child(
          V.icon('fas fa-search'),
          V.p().text('No shortcuts match your search')
        )
      ),
      
      // Navigation Tips
      V.div().class('fkh-tips').child(
        V.p().class('fkh-tips-title').text('Navigation Tips'),
        V.ul().child(
          V.li().text('Use Tab to move through the page'),
          V.li().text('Press Escape to go back or close dialogs'),
          V.li().text('Use F3-F12 to jump to page sections'),
          V.li().child('Press ', V.kbd().text('Ctrl/⌘+K'), ' to open command palette')
        )
      ),

      // Footer
      V.div().class('fkh-footer').child(
        V.span().child(V.kbd().text('↑↓'), ' Navigate'),
        V.span().class('fkh-footer-sep').text('•'),
        V.span().child(V.kbd().text('Enter'), ' Execute'),
        V.span().class('fkh-footer-sep').text('•'),
        V.span().child(V.kbd().text('Esc'), ' Close'),
        V.span().class('fkh-footer-sep').text('•'),
        V.button()
          .class(V.classes('fkh-filter-btn', helpShowActiveOnly && 'fkh-filter-btn--active'))
          .aria('pressed', helpShowActiveOnly ? 'true' : 'false')
          .child(
            V.kbd().text('F2'),
            ' Active only'
          )
      )
    ).build();
  }
  
  /**
   * Setup interactive shortcut buttons
   */
  function setupShortcutButtons() {
    if (!helpOverlay) return;

    var buttons = helpOverlay.querySelectorAll('.fkh-shortcut-btn');

    for (var i = 0; i < buttons.length; i++) {
      var button = buttons[i];

      // Click handler - execute the shortcut
      button.addEventListener('click', function() {
        var shortcutId = parseInt(this.getAttribute('data-shortcut-id'), 10);
        executeShortcutById(shortcutId);
      });

      // Enter/Space handler
      button.addEventListener('keydown', function(e) {
        if (e.key === 'Enter' || e.key === ' ') {
          e.preventDefault();
          var shortcutId = parseInt(this.getAttribute('data-shortcut-id'), 10);
          executeShortcutById(shortcutId);
        }
        // Arrow key navigation
        else if (e.key === 'ArrowDown') {
          e.preventDefault();
          focusNextShortcut(this);
        }
        else if (e.key === 'ArrowUp') {
          e.preventDefault();
          focusPreviousShortcut(this);
        }
      });
    }
  }

  /**
   * Execute a shortcut by its ID
   * @param {number} shortcutId
   */
  function executeShortcutById(shortcutId) {
    // Find the shortcut
    for (var i = 0; i < shortcuts.length; i++) {
      if (shortcuts[i].id === shortcutId) {
        var shortcut = shortcuts[i];

        // Check if in scope
        if (!isInScope(shortcut.scope)) {
          console.warn('[Funky.Keyboard] Shortcut not in current scope:', shortcut.description);
          return;
        }

        // Hide help first
        hideHelp();

        // Execute handler
        var context = shortcut.context || getScopeContext(shortcut.scope) || window;
        try {
          // Create a synthetic event
          var syntheticEvent = {
            preventDefault: function() {},
            stopPropagation: function() {},
            synthetic: true
          };
          shortcut.handler.call(context, syntheticEvent);
        } catch (error) {
          console.error('[Funky.Keyboard] Handler error:', error);
        }

        return;
      }
    }
  }

  /**
   * Focus next shortcut button
   * @param {HTMLElement} currentButton
   */
  function focusNextShortcut(currentButton) {
    var buttons = Array.prototype.slice.call(helpOverlay.querySelectorAll('.fkh-shortcut-btn:not([style*="display: none"])'));
    var currentIndex = buttons.indexOf(currentButton);
    if (currentIndex < buttons.length - 1) {
      buttons[currentIndex + 1].focus();
    }
  }

  /**
   * Focus previous shortcut button
   * @param {HTMLElement} currentButton
   */
  function focusPreviousShortcut(currentButton) {
    var buttons = Array.prototype.slice.call(helpOverlay.querySelectorAll('.fkh-shortcut-btn:not([style*="display: none"])'));
    var currentIndex = buttons.indexOf(currentButton);
    if (currentIndex > 0) {
      buttons[currentIndex - 1].focus();
    }
  }

  /**
   * Setup search filter for help overlay
   */
  function setupHelpSearch() {
    if (!helpOverlay) return;
    
    var searchInput = helpOverlay.querySelector('.fkh-search-input');
    if (!searchInput) return;
    
    // Setup filter button click
    var filterBtn = helpOverlay.querySelector('.fkh-filter-btn');
    if (filterBtn) {
      filterBtn.addEventListener('click', toggleActiveOnlyFilter);
    }
    
    searchInput.addEventListener('input', function() {
      var query = this.value.toLowerCase().trim();
      var groups = helpOverlay.querySelectorAll('.fkh-group');
      var noResults = helpOverlay.querySelector('.fkh-no-results');
      var visibleCount = 0;
      
      for (var i = 0; i < groups.length; i++) {
        var group = groups[i];
        var items = group.querySelectorAll('li');
        var groupVisible = false;
        
        for (var j = 0; j < items.length; j++) {
          var item = items[j];
          var key = item.getAttribute('data-key') || '';
          var desc = item.getAttribute('data-desc') || '';
          
          if (!query || key.indexOf(query) !== -1 || desc.indexOf(query) !== -1) {
            item.style.display = '';
            groupVisible = true;
          } else {
            item.style.display = 'none';
          }
        }
        
        group.style.display = groupVisible ? '' : 'none';
        if (groupVisible) visibleCount++;
      }
      
      // Show/hide no results message
      if (noResults) {
        noResults.style.display = (query && visibleCount === 0) ? '' : 'none';
      }
    });
    
    // Focus search on open
    setTimeout(function() {
      searchInput.focus();
    }, 100);
  }
  
  /**
   * Toggle active-only filter
   */
  function toggleActiveOnlyFilter() {
    helpShowActiveOnly = !helpShowActiveOnly;
    
    if (!helpOverlay) return;
    
    var groups = helpOverlay.querySelectorAll('.fkh-group');
    var filterBtn = helpOverlay.querySelector('.fkh-filter-btn');
    
    for (var i = 0; i < groups.length; i++) {
      var group = groups[i];
      var isActive = group.classList.contains('fkh-group--active');
      
      if (helpShowActiveOnly && !isActive) {
        group.style.display = 'none';
      } else {
        group.style.display = '';
      }
    }
    
    // Update button state
    if (filterBtn) {
      filterBtn.classList.toggle('fkh-filter-btn--active', helpShowActiveOnly);
      filterBtn.setAttribute('aria-pressed', helpShowActiveOnly ? 'true' : 'false');
    }
  }

  // ==========================================================================
  // INITIALIZATION
  // ==========================================================================

  var _keydownListenerAdded = false;

  function init() {
    if (_keydownListenerAdded) return;
    // Listen for keydown events
    document.addEventListener('keydown', handleKeydown, true);
    _keydownListenerAdded = true;

    // Register F1 for help
    register({
      key: 'f1',
      handler: toggleHelp,
      description: 'Show keyboard shortcuts',
      group: 'Help',
      priority: 1000
    });

    // Register escape to close help
    register({
      key: 'escape',
      scope: 'keyboard-help',
      handler: hideHelp,
      description: 'Close help',
      group: 'Help',
      priority: 2000
    });

    // Register F2 to toggle active-only filter
    register({
      key: 'f2',
      scope: 'keyboard-help',
      handler: toggleActiveOnlyFilter,
      description: 'Show active shortcuts only',
      group: 'Help',
      priority: 1500
    });

    // Global Escape handler with priority hierarchy
    // Low priority so component-specific handlers run first
    register({
      key: 'escape',
      scope: 'global',
      handler: function handleGlobalEscape(e) {
        // Components with higher-priority scoped Escape handlers run first.
        // This global handler is a fallback for focus management.

        // 1. Check for open context menu
        if (Funky.ContextMenu && Funky.ContextMenu.isVisible && Funky.ContextMenu.isVisible()) {
          // Context menu's own escape handler will close it
          Funky.ContextMenu.hide();
          return;
        }

        // 4. Check if we're in an input field
        var active = document.activeElement;
        var isInput = active && (
          active.tagName === 'INPUT' ||
          active.tagName === 'TEXTAREA' ||
          active.contentEditable === 'true'
        );

        if (isInput) {
          // Blur input and return to previous focus
          e.preventDefault();
          active.blur();
          if (Funky.FocusManager) {
            Funky.FocusManager.popFocus();
          }
          return;
        }

        // 5. Pop focus history (ALWAYS try this as fallback)
        if (Funky.FocusManager && Funky.FocusManager.getHistoryLength() > 0) {
          e.preventDefault();
          var success = Funky.FocusManager.popFocus();
          if (success) {
            if (Funky.Announce) {
              Funky.Announce.polite('Returned to previous focus');
            }
            return;
          }
        }

        // 6. Focus main region as final fallback
        var mainRegion = document.querySelector('[data-nav-region="main"]');
        if (mainRegion) {
          e.preventDefault();
          // Use FocusManager's selector if available, otherwise inline
          var selector = (Funky.FocusManager && Funky.FocusManager.FOCUSABLE_SELECTORS) ||
            'a[href], button:not([disabled]), input:not([disabled]):not([type="hidden"]), select:not([disabled]), textarea:not([disabled]), [tabindex]:not([tabindex="-1"])';
          var focusable = mainRegion.querySelector(selector);
          if (focusable) {
            focusable.focus();
          } else if (mainRegion.tabIndex >= 0) {
            mainRegion.focus();
          }
        }
      },
      description: 'Go back / Close',
      group: 'Navigation',
      priority: -100,  // Very low priority - components handle first
      allowInInput: true
    });

    // Tab region navigation (optional, based on preference)
    // Only active if user enables keyboard.regionTabNavigation preference
    register({
      key: 'tab',
      scope: 'global',
      preventDefault: false,  // Don't prevent Tab by default - only when we handle it
      handler: function handleTabRegion(e) {
        // Check if region tab navigation is enabled
        if (!Funky.Preferences || !Funky.Preferences.get('keyboard.regionTabNavigation')) {
          return; // Let default Tab behavior happen
        }

        // Don't intercept if FocusManager not available
        if (!Funky.FocusManager) return;

        // Check if we're at a region boundary
        var current = Funky.FocusManager.getCurrentRegion();
        if (!current) return;

        // Find focusable elements in current region
        var focusables = current.element.querySelectorAll(
          Funky.FocusManager.FOCUSABLE_SELECTORS
        );
        if (focusables.length === 0) return;

        var active = document.activeElement;
        var isLastInRegion = (active === focusables[focusables.length - 1]);
        var isFirstInRegion = (active === focusables[0]);

        // Tab at region end -> next region
        if (!e.shiftKey && isLastInRegion) {
          e.preventDefault();
          Funky.FocusManager.nextRegion();
          return;
        }

        // Shift+Tab at region start -> previous region
        if (e.shiftKey && isFirstInRegion) {
          e.preventDefault();
          Funky.FocusManager.prevRegion();
          return;
        }

        // Otherwise, let default Tab behavior happen
      },
      description: 'Navigate between regions',
      group: 'Navigation',
      priority: -200  // Very low - run after all other Tab handlers
    });

    // Global shortcuts - These emit events for app-level features to handle
    register({
      key: 'k',
      mod: true,
      handler: function() {
        document.dispatchEvent(new CustomEvent('funky.keyboard.search'));
      },
      description: 'Quick search',
      group: 'Navigation',
      priority: 100
    });

    register({
      key: ',',
      mod: true,
      handler: function() {
        document.dispatchEvent(new CustomEvent('funky.keyboard.settings'));
      },
      description: 'Open settings',
      group: 'Navigation',
      priority: 100
    });

    register({
      key: '/',
      mod: true,
      handler: toggleHelp,
      description: 'Show keyboard shortcuts',
      group: 'Help',
      priority: 100
    });

    // F6 Region Navigation - Standard accessibility shortcut
    register({
      key: 'f6',
      scope: 'global',
      handler: function() {
        if (Funky.FocusManager && Funky.FocusManager.nextRegion) {
          Funky.FocusManager.nextRegion();
        }
      },
      description: 'Next region',
      group: 'Navigation',
      priority: 50,
      allowInInput: true
    });

    register({
      key: 'f6',
      shift: true,
      scope: 'global',
      handler: function() {
        if (Funky.FocusManager && Funky.FocusManager.prevRegion) {
          Funky.FocusManager.prevRegion();
        }
      },
      description: 'Previous region',
      group: 'Navigation',
      priority: 50,
      allowInInput: true
    });
  }

  /**
   * Destroy keyboard manager and remove all listeners
   */
  function destroy() {
    if (_keydownListenerAdded) {
      document.removeEventListener('keydown', handleKeydown, true);
      _keydownListenerAdded = false;
    }
    hideHelp();
    shortcuts = [];
    scopeStack = ['global'];
  }

  // ==========================================================================
  // PUBLIC API
  // ==========================================================================

  var Keyboard = {
    // Registration
    register: register,
    unregisterScope: unregisterScope,
    unregisterGroup: unregisterGroup,

    // Scope management
    pushScope: pushScope,
    popScope: popScope,
    replaceScope: replaceScope,
    clearScopes: clearScopes,
    getCurrentScope: getCurrentScope,
    getActiveScopes: getActiveScopes,
    hasScope: hasScope,

    // Help overlay
    showHelp: showHelp,
    hideHelp: hideHelp,
    toggleHelp: toggleHelp,

    // Utilities
    formatShortcut: formatShortcut,
    getShortcuts: getShortcuts,
    isMac: isMac,

    // Lifecycle
    init: init,
    destroy: destroy,

    // For debugging
    _shortcuts: shortcuts,
    _scopeStack: scopeStack
  };

  // ==========================================================================
  // REGISTRATION
  // ==========================================================================

  if (typeof Funky !== 'undefined' && Funky.register) {
    Funky.register('Keyboard', Keyboard);
  } else {
    window.FunkyKeyboard = Keyboard;
  }

  // Auto-init immediately (don't wait for DOMContentLoaded)
  // This ensures Keyboard is available when other components initialize
  init();

})(window);

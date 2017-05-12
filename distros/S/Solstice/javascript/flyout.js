/**
 * @fileoverview 
 * Solstice provides a type of nested button called a Flyout.  This is the Javascript that supports this type of button.
 */

/**
 * @class Abstract superclass for Flyout Classes
 * @constructor
 */
Solstice.Flyout = function () {};

/**
 * @class The flyout menu object - this obj is responsible for
 * keeping track of the button data.
 * @constructor
 * @param {string} id An identifier for the new Flyout menu
 */
Solstice.Flyout.Menu = function(id) {
    this.id = id;
    this.options = new Array();
    this.style = 'sol_flyoutmenu'; // default style class
}

/**
 * Adds options to the menu
 * @param {array} list A list of attributes for the options
 * @private
 * @type void
 */
Solstice.Flyout.Menu.prototype.createOptions = function(list) {
    for (i = 0; i < list.length; i++) {
        this.options[this.options.length] = new Solstice.Flyout.MenuOption(list[i]);
    }
}

/**
 * Sets the CSS style class name of the menu
 * @param {string} style CSS classname
 * @type void
 */
Solstice.Flyout.Menu.prototype.setStyleClass = function(style) {
    this.style = style;
}


/**
 * @class Models the options that make up a Flyout.Menu
 * @constructor
 * @param {array} list A list of attributes that describe the option
 * @type void
 */
Solstice.Flyout.MenuOption = function(list) {
    this.buttonid  = list[0];
    this.label     = list[1];
    this.title     = list[2];
    this.url       = list[3];
    this.is_static = list[4];
    this.disabled  = list[5];
    this.checked   = list[6];
    if (list[0] && list[7]) {
        Solstice.Button.registerClientAction(list[0], list[7]);
    }
}

/**
 * @class A registry of flyouts on the screen
 * @constructor
 * @param {string} id An identifier for the registry
 */
Solstice.Flyout.MenuRegistry = function(id) {
    this.id = id;
    this.registry = new Array();
}

/**
 * Factory type method that create a flyout menu while adding it to the registry
 * @param {string} id an id for the flyout
 * @param {array} options A list of attributes for the flyout
 */
Solstice.Flyout.MenuRegistry.prototype.createMenu = function(id, options) {
    if (this.registry[id]) return this.registry[id]; 
    
    var menu = new Solstice.Flyout.Menu(id);
    if (options) menu.createOptions(options);
    
    this.registry[id] = menu;
    
    return menu;
}

Solstice.Flyout.MenuRegistry.prototype.clickSubmit = function(p_sType, p_aArgs, p_oValue) {
    return Solstice.Button.submit(p_oValue);
}

Solstice.Flyout.MenuRegistry.prototype.clickAlternateSubmit = function(p_sType, p_aArgs, p_oValue) {
    return Solstice.Button.alternateSubmit(p_oValue.url, p_oValue.id);
}


/**
 * Opens a the Flyout menu.
 * @param {string} current_id The ID of the flyout to open
 * @param {event} event The event that spawned the menu (used to locate the menu on the screen)
 * @returns {boolean} Did the menu open successfully?
 */
Solstice.Flyout.MenuRegistry.prototype.openMenu = function(current_id, event) {
    if (!current_id) return false;

    if (!this.menu) {
        this.menu = new Array();
    }

    if (this.menu[current_id]) {
        YAHOO.widget.MenuManager.hideVisible();
        return this._openMenu(current_id, event);
    }

    var yahoo_menu = new YAHOO.widget.Menu("menu_"+current_id);

    this.menu[current_id] = yahoo_menu;

    // If this menu has already been created, just display it.
    if (yahoo_menu.getItems().length) {
        return this._openMenu(current_id, event);
    }

    // Get the menu for the selected id
    var menu = this.registry[current_id];
    if (!menu.options.length) return false;
    var menuClass = menu.style;

    for (i = 0; i < menu.options.length; i++) {
        yahoo_menu.addItem({
            text: menu.options[i].label,
            url: (menu.options[i].is_static && menu.options[i].url != '') ? menu.options[i].url : undefined,
            onclick: (!menu.options[i].is_static && menu.options[i].url != '')
                ? { fn:this.clickAlternateSubmit, obj:{id:menu.options[i].buttonid, url:menu.options[i].url} } 
                : { fn:this.clickSubmit, obj:menu.options[i].buttonid },
            disabled:menu.options[i].disabled,
            checked:menu.options[i].checked
        });
    }

    yahoo_menu.render(document.body);

    // This loop needs to happen after the menu has been rendered, otherwise the tooltips won't show up.
    for (i = 0; i < menu.options.length; i++) {
        var item = yahoo_menu.getItem(i);
        var tooltip = Solstice.YahooUI.tooltip("solstice_tooltip_"+item.id, { context: item.id, text: menu.options[i].title });
    }

    return this._openMenu(current_id, event);
}

/**
 * Opens the Flyout menu, after determining the location.
  * @param {string} current_id The ID of the flyout to open
  * @param {event} event The event that spawned the menu (used to locate the menu on the screen)
  * @returns {void}
  */
Solstice.Flyout.MenuRegistry.prototype._openMenu = function(current_id, event) {
    var yahoo_menu = this.menu[current_id];

    // In order to display menu next to the current
    // object we need to get coordinates of the click.
    // Netscape and IE do this differently.
    if (!event) event = window.event;

    var Xpt = Solstice.Geometry.getEventX(event);
    var Ypt = Solstice.Geometry.getEventY(event);

    if (Xpt < 10 && Ypt < 10) {
        var target = document.getElementById(current_id);
        Xpt = target.offsetLeft + (target.offsetWidth / 2);
        Ypt = target.offsetTop + (target.offsetHeight / 2);
    }

    // Don't allow the menu to display offscreen
    var container = document.getElementById(yahoo_menu.id);
    if (container.offsetHeight > (Solstice.Geometry.getBrowserHeight() - Ypt)) Ypt = Ypt - container.offsetHeight;
    if (container.offsetWidth > (Solstice.Geometry.getBrowserWidth() - Xpt)) Xpt = Xpt - container.offsetWidth;

    // Move the menu into view
    container.style.top = Ypt + 'px';
    container.style.left = Xpt + 'px';

    yahoo_menu.show();

    return;
}

/**
 * Solstice only uses one MenuRegistry - it's held here.
 */
Solstice.Flyout.menuReg = new Solstice.Flyout.MenuRegistry('sol_flyoutmenu');

/*
 * Copyright  1998-2006 Office of Learning Technologies, University of Washington
 * 
 * Licensed under the Educational Community License, Version 1.0 (the "License");
 * you may not use this file except in compliance with the License. You may obtain
 * a copy of the License at: http://www.opensource.org/licenses/ecl1.php
 * 
 * Unless required by applicable law or agreed to in writing, software distributed
 * under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
 * CONDITIONS OF ANY KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations under the License.
 */

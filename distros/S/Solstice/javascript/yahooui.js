
Solstice.YahooUI = function(){};

/** Scrolling **/

Solstice.YahooUI.inTopScrollArea = false;
Solstice.YahooUI.inBottomScrollArea = false;
Solstice.YahooUI.scrollInterval = 10;
Solstice.YahooUI.scrollDistance = 5;


Solstice.YahooUI.tooltip_showdelay = 750;
Solstice.YahooUI.tooltip_hidedelay = 50;
Solstice.YahooUI.tooltip_autodismiss = 5000;
// This is to keep tooltips above flyout menus.  Hopefully no flyout menu is launched from an element at zindex of 998 or higher.  This could be improved.
Solstice.YahooUI.tooltip_zindex = 999;

Solstice.YahooUI.tooltip = function(title, args) {

    YAHOO.namespace("solstice.container");
    
    var delayargs = {
        showdelay:Solstice.YahooUI.tooltip_showdelay, 
        hidedelay:Solstice.YahooUI.tooltip_hidedelay, 
        autodismissdelay:Solstice.YahooUI.tooltip_autodismiss,
        zindex: Solstice.YahooUI.tooltip_zindex
        };

    for (key in args) {
        delayargs[key] = args[key];
    }
    return new YAHOO.widget.Tooltip(title, delayargs );
}

Solstice.YahooUI.scrollDown = function (){
    if(Solstice.YahooUI.inBottomScrollArea){
        window.scrollTo(0, Solstice.Geometry.getScrollYOffset() + Solstice.YahooUI.scrollDistance);
        setTimeout('Solstice.YahooUI.scrollDown();', Solstice.YahooUI.scrollInterval);
    }
}

Solstice.YahooUI.scrollUp = function (){
    if(Solstice.YahooUI.inTopScrollArea){
        window.scrollTo(0, Solstice.Geometry.getScrollYOffset() - Solstice.YahooUI.scrollDistance);
        setTimeout('Solstice.YahooUI.scrollUp();', Solstice.YahooUI.scrollInterval);
    }
}

Solstice.YahooUI.dropIndicator = document.createElement('div');
Solstice.YahooUI.dropIndicator.id = 'solstice_yahooui_drop_indicator';

Solstice.YahooUI.addHorizontalSortItem = function (group, id, options) {
    var dd = new YAHOO.util.DDProxy(id, group);
    dd.setYConstraint(0,0);
    Solstice.YahooUI._addSortItem(dd, group, id, options);
}
Solstice.YahooUI.addVerticalSortItem = function (group, id, options){
    var dd = new YAHOO.util.DDProxy(id, group);
    dd.setXConstraint(0,0);
    Solstice.YahooUI._addSortItem(dd, group, id, options);
}

Solstice.YahooUI.addSortItem = function (group, id, options) {
    var dd = new YAHOO.util.DDProxy(id, group);
    Solstice.YahooUI._addSortItem(dd, group, id, options);
}

Solstice.YahooUI._addSortItem = function (dd, group, id, options) {
    dd.scroll = false;
    dd.group = group;
    if(options){
        if(options.handle) { 
            dd.setHandleElId(options.handle);
        }
        if(options.callback){
            dd.callback = options.callback;
        }
    }
    YAHOO.util.DDM.clickPixelThresh = 10;
    YAHOO.util.DDM.clickTimeThresh = 150;

    dd.startDrag = function() {
        document.getElementById(this.id).style.opacity = 0.5;
        document.getElementById(id).style.filter = "alpha(opacity = 50)";
        Solstice.YahooUI.inBottomScrollArea = false;
        Solstice.YahooUI.inTopScrollArea = false;
        
        // Add an event to handle out-of-bounds drops
        Solstice.Event.add(document, 'mouseup', Solstice.YahooUI.hideDropIndicator);
    };

    dd.endDrag = function() {
        Solstice.YahooUI.fadeIn(this.id, 0.5, 1);
        Solstice.YahooUI.inBottomScrollArea = false;
        Solstice.YahooUI.inTopScrollArea = false;
    };

    //dd.onDrag = function (e){
    //}
   
    dd.onDragEnter = function(e, id) {
        height = Solstice.Geometry.getBrowserHeight();
        scroll_top = Solstice.Geometry.getScrollYOffset();
        event_top = Solstice.Geometry.getEventY(e);

        if(((scroll_top + height) - event_top) < 50 ){
            if(!Solstice.YahooUI.inBottomScrollArea){
                Solstice.YahooUI.inBottomScrollArea = true;
                Solstice.YahooUI.scrollDown();
            }
        }else{
            Solstice.YahooUI.inBottomScrollArea = false;
        }

        if((event_top - scroll_top) < 50 ){
            if(!Solstice.YahooUI.inTopScrollArea){
                Solstice.YahooUI.inTopScrollArea = true;
                Solstice.YahooUI.scrollUp();
            }
        }else{
            Solstice.YahooUI.inTopScrollArea = false;
        }


    };

    dd.onDragOver = function(e, id){

        target = document.getElementById(id);

        // Be sure to define this css class in your stylesheet!
        Solstice.YahooUI.dropIndicator.className = 'solstice_yahooui_drop_indicator_' + this.group;
        Solstice.YahooUI.dropIndicator.style.display = 'block';
        
        if(target.top){
            target.parentNode.insertBefore(Solstice.YahooUI.dropIndicator, target.nextSibling);
        }else{
            target.parentNode.insertBefore(Solstice.YahooUI.dropIndicator, target);
        }
    };

    dd.onDragOut = function(e, id) {
        Solstice.YahooUI.hideDropIndicator();
    };

    dd.onDragDrop = function(e, id) {
        target = document.getElementById(id);
        dragging = document.getElementById(this.id);

        Solstice.YahooUI.hideDropIndicator();
        
        if(target.top){
            dragging.parentNode.removeChild(dragging);
            target.parentNode.replaceChild(dragging, target);
            dragging.parentNode.insertBefore(target, dragging);
        }else{
            dragging.parentNode.removeChild(dragging);
            target.parentNode.insertBefore(dragging, target);
        }
        YAHOO.util.DDM.refreshCache(this.groups);
    
        if(this.callback){
            this.callback();
        }
    };

}

Solstice.YahooUI.addVerticalSortTopTarget = function(group, id){
    var dd = new YAHOO.util.DDTarget(id, group);
    document.getElementById(id).top = true;
}

Solstice.YahooUI.addVerticalSortBottomTarget = function(group, id){
    var dd = new YAHOO.util.DDTarget(id, group);
    document.getElementById(id).bottom = true;
}

Solstice.YahooUI.hideDropIndicator = function() {
    Solstice.YahooUI.dropIndicator.style.display = 'none';
    Solstice.Event.remove(document, 'mouseup', Solstice.YahooUI.hideDropIndicator);
}


/** Fades **/

Solstice.YahooUI.fadeIn = function (id, duration, to) {
    if(!to){
        to = 1;
    }
    //stupid hack - safari sometimes lets faded content disappear
    if(to == 1){
        to = 0.9999;
    }
    if(!duration){
        duration = 2;
    }
    var anim = new YAHOO.util.Anim(id, { opacity: { to: to } }, duration, YAHOO.util.Easing.easeBoth);
    anim.animate();
}

Solstice.YahooUI.fadeOut = function (id, duration, to) {
    if(!to){
        to = 0;
    }
    if(!duration){
        duration = 2;
    }
    var anim = new YAHOO.util.Anim(id, { opacity: { to: to} }, duration, YAHOO.util.Easing.easeBoth);
    anim.animate();
}


/** Hide/shows **/

Solstice.YahooUI._setClear = function (id) {
    var element = document.getElementById(id);

    element.style.opacity = 0;
    element.style['-moz-opacity'] = 0;
    element.style['-khtml-opacity'] = 0;
    element.style.filter = 'alpha(opacity=0)';

    if (!element.currentStyle || !element.currentStyle.hasLayout) {
        element.style.zoom = 1; // when no layout or cant tell
    }

}

Solstice.YahooUI.showBlock = function (id) {
    Solstice.YahooUI._setClear(id);
    var element = document.getElementById(id);

    element.style.display = "block";
    Solstice.YahooUI.fadeIn(id, 0.5);
}

Solstice.YahooUI.showInline = function (id) {
    Solstice.YahooUI._setClear(id);
    var element = document.getElementById(id);

    element.style.display = "inline";
    Solstice.YahooUI.fadeIn(id, 1);
}


Solstice.YahooUI.hide = function (id) {
    Solstice.YahooUI.fadeOut(id, 0.5);
    window.setTimeout("document.getElementById('"+id+"').style.display = \"none\"", 500);
}

Solstice.YahooUI.toggleInline = function (id) {
    var block_obj = document.getElementById(id);
    if (block_obj.style.display == "none"){
        Solstice.YahooUI.showInline(id);
    }else{
        Solstice.YahooUI.hide(id);
    }
}

Solstice.YahooUI.toggleBlock = function (id) {
    var block_obj = document.getElementById(id);
    if (block_obj.style.display == "none"){

        Solstice.YahooUI.showBlock(id);
    }else{
        Solstice.YahooUI.hide(id);
    }
}

Solstice.YahooUI.PopIn = function(){};
Solstice.YahooUI.PopIn.init = function() {
/*
    Solstice.YahooUI.PopIn = new YAHOO.widget.Dialog("solstice_popin",
        { 
            modal : true,
            fixedcenter : true,
            visible : false,
            constraintoviewport : true
        } );

    var handle = function() {
       return false;
    };

    Solstice.YahooUI.PopIn.callback= {success:handle, failure:handle };
    Solstice.YahooUI.PopIn.render();
    */
    if(Solstice.YahooUI.PopIn.cfg != null){
        return true;
    }

   Solstice.YahooUI.PopIn = new YAHOO.widget.Panel("simpledialog1",
                                                    {
                                                        modal : true,
                                                       // fixedcenter: false,
                                                        visible: false,
                                                        draggable: false,
                                                        close: true,
                                                        icon: YAHOO.widget.SimpleDialog.ICON_HELP,
                                                        constraintoviewport: true,
                                                        iframe: true,
                                                        underlay: 'shadow'
                                                    } );

    Solstice.YahooUI.PopIn.setHeader('header');
    Solstice.YahooUI.PopIn.render(document.getElementById('solstice_app_form'));

}

Solstice.YahooUI.raisePopIn = function(button_name, is_modal, is_draggable, width) {

    if(Solstice.YahooUI.PopIn.cfg == null){
        //make sure our popin has been inited(this was put here for ie)
        Solstice.YahooUI.PopIn.init();
    }
    
    if (button_name && !is_modal) {
        var elements = document.getElementsByName(button_name);
        if (elements && elements[0]) {
            Solstice.YahooUI.PopIn.cfg.setProperty('context', [elements[0], 'tl', 'tl']);
        }
    }
    else {
        Solstice.YahooUI.PopIn.cfg.setProperty('fixedcenter', true);
    }
    
    Solstice.YahooUI.PopIn.cfg.setProperty('modal', (is_modal)? true:false);
    Solstice.YahooUI.PopIn.cfg.setProperty('draggable', (is_draggable) ? true:false);
    if(width){
        Solstice.YahooUI.PopIn.cfg.setProperty('width', width);
    }
    
    //by default we show the closing img... should we make this configurable in perl?
    Solstice.YahooUI.PopIn.cfg.setProperty('close', true);

    Solstice.YahooUI.setPopInContent("Please wait... <img src=\"images/processing.gif\" alt=\"Processing\" style=\"vertical-align:middle;\">");
    Solstice.YahooUI.setPopInTitle("&nbsp;");
    
    Solstice.Button.set(button_name);
    Solstice.Button.performClientAction();

    Solstice.YahooUI.PopIn.show();
}

Solstice.YahooUI.lowerPopIn = function() {
    Solstice.YahooUI.PopIn.hide();
    return false;
}

Solstice.YahooUI.setPopInContent = function(content) {
    var regEx = /<script type="text\/javascript">(.+?)<\/script>/g;
    Solstice.YahooUI.PopIn.setBody(content);
   
    var result;
    // we need to run any inline javascript (ie register clientactions, etc)
    while((result = regEx.exec(content)) != null){
        eval(result[1]);
    }

    Solstice.YahooUI.PopIn.render();
    if (Solstice.YahooUI.PopIn.cfg.getProperty('fixedcenter')) {
        Solstice.YahooUI.PopIn.center();
    }
}

Solstice.YahooUI.setPopInTitle = function(title) {
    Solstice.YahooUI.PopIn.setHeader(title);
}

YAHOO.util.Event.addListener(window, "load", Solstice.YahooUI.PopIn.init);

Solstice.YahooUI.Calendar = [];
Solstice.YahooUI.Calendar.init = function(name, button_id, format, mindate, maxdate, on_select_handler) {
    var element = document.getElementById(button_id);
    if (!element) {
        return;
    }
    Solstice.YahooUI.Calendar[button_id] = new YAHOO.widget.Calendar(name, button_id, {close:true,'mindate':mindate,'maxdate':maxdate, iframe:true});
    
    Solstice.YahooUI.Calendar[button_id].selectEvent.subscribe(Solstice.YahooUI.Calendar.handleSelect, Solstice.YahooUI.Calendar[button_id], true);
   
    Solstice.YahooUI.Calendar.update(name);
  
    // Add the application-level handler AFTER the initial update() above.
    if (on_select_handler) {
        Solstice.YahooUI.Calendar[button_id].selectEvent.subscribe(on_select_handler);
    }
   
    Solstice.YahooUI.Calendar[button_id].hide();
}

Solstice.YahooUI.Calendar.handleSelect = function(type,args,obj) { 
    var dates = args[0];  
    var date = dates[0]; 
    var year = date[0], month = date[1], day = date[2]; 
    
    if(year && month && day){
        var txtDate1 = document.getElementById(this.id+"_date"); 
        txtDate1.value = month + "/" + day + "/" + year;
    }
    
    obj.hide();
}

Solstice.YahooUI.Calendar.show = function(id) {
    Solstice.YahooUI.Calendar[id].show();
    return false;
}

Solstice.YahooUI.Calendar.update = function(id) {
    var txtDate = document.getElementById(id+"_date");
    if(txtDate){
        Solstice.YahooUI.Calendar[id+"_button"].select(txtDate.value);
        var firstDate = Solstice.YahooUI.Calendar[id+"_button"].getSelectedDates()[0];
        if(firstDate && firstDate != "Invalid Date" && firstDate != "NaN"){
            Solstice.YahooUI.Calendar[id+"_button"].cfg.setProperty('pagedate', (firstDate.getMonth()+1)+ "/" + firstDate.getFullYear());
        }
    }
    //render has to be called in update (if the users changes the text input the calendar needs to be redrawn)
    Solstice.YahooUI.Calendar[id+"_button"].render();
}

/*
* Copyright  1998-2007 Office of Learning Technologies, University of Washington
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

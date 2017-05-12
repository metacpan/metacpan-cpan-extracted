// CSS Browser Selector   v0.2.5
// Documentation:         http://rafael.adm.br/css_browser_selector
// License:               http://creativecommons.org/licenses/by/2.5/
// Author:                Rafael Lima (http://rafael.adm.br)
// Contributors:          http://rafael.adm.br/css_browser_selector#contributors
var css_browser_selector = function() {
	var 
		ua=navigator.userAgent.toLowerCase(),
		is=function(t){ return ua.indexOf(t) != -1; };
    var b=(!(/opera|webtv/i.test(ua))&&/msie (\d)/.test(ua)) ? ('ie ie'+RegExp.$1) :
            is('gecko/') ? 'gecko' : 
            is('opera/9') ? 'opera opera9' :
            /opera (\d)/.test(ua) ? 'opera opera'+RegExp.$1 : 
            is('konqueror') ? 'konqueror' : 
            is('applewebkit/') ? 'webkit safari' : 
            is('mozilla/') ? 'gecko' : '',
        os=(is('x11')||is('linux')) ? ' linux' : 
            is('mac') ? ' mac':
            is('win') ? ' win':'';
    var bm= /firefox\/(\d+)\.(\d+)/.test(ua) ? 
                    ' firefox firefox'+RegExp.$1+
                    ' firefox'+RegExp.$1+'_'+RegExp.$2 :
            is('explorer') ? ' explorer' : '';
	var c=b+os+bm+' js';
    fb_log( c );
    fb_dir( h );
    var h = document.documentElement;
	h.className += h.className?' '+c:c;
    return c;
}();
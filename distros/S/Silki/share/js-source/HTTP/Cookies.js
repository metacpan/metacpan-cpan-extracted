// HTTP.Cookies by Burak Gürsoy <burak[at]cpan[dot]org>
if (!HTTP) var HTTP = {};

HTTP.Cookies = function () {
   this._reset();
}

// expire time calculation
HTTP.Cookies.Date = function () {
   this._init();
}

HTTP.Cookies.VERSION     = '1.11';
HTTP.Cookies.ERRORLEVEL  = 1;
HTTP.Cookies.Date.FORMAT = {
   's' :  1,
   'm' : 60,
   'h' : 60 * 60,
   'd' : 60 * 60 * 24,
   'M' : 60 * 60 * 24 * 30,
   'y' : 60 * 60 * 24 * 365
};

HTTP.Cookies.prototype._reset = function () {
   this['JAR']     = ''; // data cache
   this['CHANGED'] =  0; // cookies altered?
}

// Get the value of the named cookie. Usage: password = cookie.read('password');
HTTP.Cookies.prototype.read = function (name) {
	if(!name) return this._fatal('read', 'Cookie name is missing');
   if(this.CHANGED) this._reset();
   // first populate the internal cache, then return the named cookie
   var value = '';
   this._parse();
   for ( var cookie in this.JAR ) {
      if ( cookie == name ) {
         value = this.JAR[cookie];
         break;
      }
	}
   return value ? value : '';
}

// Create a new cookie or overwrite existing.
// Usage: cookie.write('password', 'secret', '1m');
HTTP.Cookies.prototype.write = function (name, value, expires, path, domain, secure) {
	if(!name) return this._fatal('write', 'Cookie name is missing');
	if(typeof value == 'undefined') value = ''; // workaround
   if (!expires) expires = '';
   if (expires == '_epoch') {
      expires = new Date(0);
   }
   else if (expires != -1) {
      var cdate = new HTTP.Cookies.Date;
      var Now   = new Date;
      Now.setTime(Now.getTime() + cdate.parse(expires));
      expires = Now.toGMTString();
   }
   var extra = '';
   if(expires) extra += '; expires=' + expires;
   if(path   ) extra += '; path='    + path;
   if(domain ) extra += '; domain='  + domain;
   if(secure ) extra += '; secure='  + secure;
   // name can be non-alphanumeric
   var new_cookie  = escape(name) + '=' + escape(value) + extra;
   document.cookie = new_cookie;
   this.CHANGED    = 1; // reset the object in the next call to read()
}

// Delete the named cookie. Usage: cookie.remove('password');
HTTP.Cookies.prototype.remove = function (name, path, domain, secure) {
	if(!name) return this._fatal('remove', 'Cookie name is missing');
   this.write(name, '', '_epoch', path, domain, secure);
}

// cookie.obliterate()
HTTP.Cookies.prototype.obliterate = function () {
   var names = this.names();
   for ( var i = 0; i < names.length; i++ ) {
		if ( !names[i] ) continue;
      this.remove( names[i] );
	}
}

// var cnames = cookie.names()
HTTP.Cookies.prototype.names = function () {
   this._parse();
   var names = [];
   for ( var cookie in this.JAR ) {
		if ( !cookie ) continue;
      names.push(cookie);
	}
	return names;
}

HTTP.Cookies.prototype._parse = function () {
   if(this.JAR) return;
	this.JAR  = {};
   var NAME  = 0; // field id
   var VALUE = 1; // field id
   var array = document.cookie.split(';');
   for ( var element = 0; element < array.length; element++ ) {
      var pair = array[element].split('=');
      pair[NAME] = pair[NAME].replace(/^\s+/, '');
      pair[NAME] = pair[NAME].replace(/\s+$/, '');
      // populate
      this.JAR[ unescape(pair[NAME]) ] = unescape( pair[VALUE] );
   }
}

HTTP.Cookies.prototype._fatal = function (caller, error) {
   var title = 'HTTP.Cookies fatal error';
   switch(HTTP.Cookies.ERRORLEVEL) {
      case 1:
         alert( title + "\n\n"  + caller + ': ' + error );
         break;
      default:
         break;
   }
}

HTTP.Cookies.Date.prototype._fatal = function (caller, error) {
   var title = "HTTP.Cookies.Date fatal error";
   switch(HTTP.Cookies.ERRORLEVEL) {
      case 1:
         alert( title + "\n\n"  + caller + ': ' + error );
         break;
      default:
         break;
   }
}

// HTTP.Cookies.Date Section begins here

HTTP.Cookies.Date.prototype._init = function () {
   this.FORMAT = HTTP.Cookies.Date.FORMAT;
}

HTTP.Cookies.Date.prototype.parse = function (x) {
   if(!x || x == 'now') return 0;
   var NUMBER = 1;
   var LETTER = 2;
   var date = x.match(/^(.+?)(\w)$/i);

   if ( !date ) {
		return this._fatal(
			       'parse',
			       'expires parameter (' + x + ') is not valid'
			    );
	}

   var is_num = this.is_num(  date[NUMBER] );
   var of     = this.is_date( date[NUMBER], date[LETTER] );
   return (is_num && of) ? of : 0;
}

HTTP.Cookies.Date.prototype.is_date = function (num, x) {
   if (!x || x.length != 1) return 0;
   var ar = [];
   return (ar = x.match(/^(s|m|h|d|w|M|y)$/) ) ? num * 1000 * this.FORMAT[ ar[0] ] : 0;
}

HTTP.Cookies.Date.prototype.is_num = function (x) {
   if (x.length == 0) return;
   var ok = 1;
   for (var i = 0; i < x.length; i++) {
      if ( "0123456789.-+".indexOf( x.charAt(i) ) == -1 ) {
         ok--;
         break;
      }
   }
   return ok;
}

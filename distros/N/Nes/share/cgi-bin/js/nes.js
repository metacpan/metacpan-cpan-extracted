var nes_js_load = true;
var nes_js_ver  = '1.03';

function nesIncludeJs(file,time) {
    var js  = document.createElement("script");
    js.type = "text/javascript";
    js.src  = file;
    setTimeout("document.body.appendChild(js);",time);
}




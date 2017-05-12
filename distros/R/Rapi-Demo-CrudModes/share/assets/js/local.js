/* Optional app-specific JavaScript goes here */

RA.ux.CM = {};

RA.ux.CM.showCrudEl = function(title,el) {
  if(el && el.nextElementSibling) {
  
    var content = el.nextElementSibling.innerHTML;
    content = content.replace(/1/g,'<b style="color:green;font-size:1.2em;">1</b>');
    content = content.replace(/0/g,'<b style="color:crimson;font-size:1.2em;">0</b>');
  
    Ext.Msg.show({
      title: title,
      msg: ['<div>',content,'</div>'].join("\n"),
      buttons: Ext.Msg.OK,
      icon: Ext.Msg.INFO,
      width: 350
    });
  }
};


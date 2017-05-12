document.onmousemove = drag;
document.onmouseup = drop;
defaultAction ='news';
m_blogin = false;
cAction = defaultAction;
function initCms()
{
  var closeButton = $("closeButton");
  closeButton.addEventListener ('click',closePopup);
  loadMenu();
  loadHistory();
  $('menu').addEventListener ('click', function (evt) {
     menu();
    evt.stopPropagation();
  });
  var menuButton = document.getElementById("menuButton");
  menuButton.addEventListener ('click', function (evt) {
    menu();
    evt.stopPropagation();
  });
}
var menuAktive = false;  
function menu(){
  var node = document.getElementById('menu');
  if(menuAktive){
    hide('menuContent');
    node.classList.add('closed');
    menuAktive = false;
  }else{
    node.classList.remove('closed');
    visible('menuContent');
    menuAktive = true;
  }
}
function loadMenu(){
  var oMenu = loadXMLDoc('cgi-bin/menu.pl');
  loadPage(oMenu,'xsl/action.xsl','tab');
  loadPage(oMenu,'xsl/main.xsl','menu');
}
function closeMenu(){}
defaultAction ='ShowDatabases';
m_blogin = true;
cAction = defaultAction;

function init()
{
  var oMenu = loadXMLDoc('xml/action.xml');
  loadPage(oMenu,'xsl/action.xsl','tab');
  loadPage(oMenu,'xsl/menu.xsl','menu');
  translate();
  loadHistory();
  var menuButton = document.getElementById("menuButton");
  menuButton.addEventListener ('click', function (evt) {
    if(!menuAktive)
      menu();
    else
      closeMenu();
    evt.stopPropagation();
  });
}
var menuAktive = false;
var wsize     = getWindowSize();
function menu(){
  var ao = getWindowSize();
  if(!menuAktive){
    document.getElementById('menu').classList.remove('closed');
    visible('menuContent');
    visible('closeMenu');
    document.getElementById('menu').width= sidebarX;
    document.getElementById('menu').style.minWidth = sidebarX;
    document.getElementById('con').width = (ao.x-ScrolBarWidth() - sidebarX )+'px';
    menuAktive = true;
    showTab('tab1')
  }
  var node = document.getElementById("closeMenu");
  node.addEventListener ('click', function (evt){
    if(menuAktive){
      closeMenu();
    }
    evt.stopPropagation();
  }
  );
}
function closeMenu()
{
  hide('menuContent');
  hide('closeMenu');
  document.getElementById('con').width= (wsize.x -5) +"px";
  document.getElementById('menu').width='5px';
  document.getElementById('menu').style.minWidth = '5px';
  document.getElementById('menu').classList.add('closed');
  menuAktive = false;
}
var bSidebarResize = false;
var sidebarX = 300;
document.onmousemove = resizeSidebar;
document.onmousedown = startResize;
document.onmouseup = stopResize;
function startResize(EVENT){
  var posX = document.all ? window.event.clientX : EVENT.pageX;
  var pos =getElementPosition('content');
  
  if(sidebarX >  posX -5  &&  sidebarX   <  posX +5  )
  {
	sidebarX = pos.x; 
    document.getElementById('menu').style.cursor="ew-resize";
    bSidebarResize =  true;
    document.getElementById('menu').classList.add('noselect');
    document.getElementById('menu').setAttribute('unselectable','on');
  }
}
function stopResize(EVENT){
  bSidebarResize = false;
  document.getElementById('menu').style.cursor="";
  document.getElementById('menu').classList.remove('noselect');
  document.getElementById('menu').setAttribute('unselectable','off');
  drop(EVENT);
}
function resizeSidebar(EVENT){
  posX = document.all ? window.event.clientX : EVENT.pageX;
  posY = document.all ? window.event.clientY : EVENT.pageY;
  if(bSidebarResize && posX > 5  && posX  <  500)
  {
    document.getElementById('menu').width= posX+'px';
    document.getElementById('menu').style.minWidth= posX+'px';
    sidebarX = posX;
    var ao = getWindowSize();
    document.getElementById('con').width = (ao.x-ScrolBarWidth() - posX )+'px';
    return;
  }
  if(sidebarX >  posX -5  &&  sidebarX   <  posX +5  )
  {
      document.getElementById('menu').style.cursor="ew-resize";
  }
  else
  {
      if(document.getElementById('menu'))
	document.getElementById('menu').style.cursor= "";
  }
  drag(EVENT);
}
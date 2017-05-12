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
    $('menu').classList.remove('closed');
    visible('menuContent');
    visible('closeMenu');
    $('menu').width= sidebarX;
    $('menu').style.minWidth = sidebarX;
    $('con').width = (ao.x-ScrolBarWidth() - sidebarX )+'px';
    menuAktive = true;
    showTab('tab1')
  }
  var node = $("closeMenu");
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
  $('con').width= (wsize.x -5) +"px";
  $('menu').width='5px';
  $('menu').style.minWidth = '5px';
  $('menu').classList.add('closed');
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
  sidebarX = pos.x;  
  if(sidebarX >  posX -5  &&  sidebarX   <  posX +5  )
  {
    $('menu').style.cursor="ew-resize";
    bSidebarResize =  true;
    $('menu').classList.add('noselect');
    $('menu').setAttribute('unselectable','on');
  }
}
function stopResize(EVENT){
  bSidebarResize = false;
  $('menu').style.cursor="";
  $('menu').classList.remove('noselect');
  $('menu').setAttribute('unselectable','off');
  drop(EVENT);
}
function resizeSidebar(EVENT){
  posX = document.all ? window.event.clientX : EVENT.pageX;
  posY = document.all ? window.event.clientY : EVENT.pageY;
  if(bSidebarResize && posX > 5  && posX  <  500)
  {
    $('menu').width= posX+'px';
    $('menu').style.minWidth= posX+'px';
    sidebarX = posX;
    var ao = getWindowSize();
    $('con').width = (ao.x-ScrolBarWidth() - posX )+'px';
    return;
  }
  if(sidebarX >  posX -5  &&  sidebarX   <  posX +5  )
  {
      $('menu').style.cursor="ew-resize";
  }
  else
  {
      if($('menu'))
	$('menu').style.cursor= "";
  }
  drag(EVENT);
}
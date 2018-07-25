<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
<xsl:template match="/">
<div align="right" width="100%"><div class="closeMenu" id="closeMenu" style="display:none;">X</div></div>
<div class="menuContainer" align="center">
<div id="menuContent" class="verticalMenuLayout" style="overflow:hidden;display:none;">
<div align="center">
<div id="quickbar"></div>
<table width="100%">
<tr><td class="menuCaption"><b><a class="menupoint" onclick="showTab('tab0')">Login</a></b></td></tr>
<tr id="tab0" class="cnt"><td id="loginContent" style="text-align:center;" ></td></tr>
<tr><td class="menuCaption"><b><a class="menupoint" onclick="showTab('tab1')" >Navigation</a></b></td></tr>
<tr id="tab1" class="cnt closed"><td id="treeview" class="menuContent" style="display:none;"></td></tr>
</table>
</div>
</div>
</div>
</xsl:template>
</xsl:stylesheet>

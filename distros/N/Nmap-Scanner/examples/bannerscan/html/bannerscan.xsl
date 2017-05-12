<?xml version="1.0" encoding="iso-8859-1"?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
  <html>
   <head>
     <title>bannerscan results</title>
      <link rel="stylesheet" type="text/css" media="all" href="bannerscan.css" /> 
   </head>
   <body id="kismet">
    <div id="header">
     <h1>bannerscan results</h1>
    </div>
    <div id="container">
     <div id="intro">
      <img src="img/logo_head.png" border="0" alt="Results of bannerscan" />
      <p><span>Here are the results of bannerscan. You can see only the hosts
      which are up and running.</span></p>
     </div>
     <div id="hostlist">
      <h3>Select a host: </h3>
      <xsl:if test="/nmaprun/host/status/@state='up'">
       <xsl:for-each select="/nmaprun/host/address/@addr">
        <xsl:sort select='.' data-type='text' />
	 <a>
	  <xsl:attribute name="href">#<xsl:value-of select='.' />
          </xsl:attribute><xsl:value-of select='.' /><br /></a>
       </xsl:for-each>
      </xsl:if>
     </div>
     <xsl:apply-templates />
     <div id="footer">
      <h3>bannerscan a project by MM - webstuff by AMP</h3>
     </div>
    </div>
   </body>
  </html>
</xsl:template>

<xsl:template match="host">
 <div id="host">
  <xsl:if test="status/@state='up'">
   <a><xsl:attribute name="name"><xsl:value-of select='address/@addr' /></xsl:attribute> </a>
   <h3>Host: <xsl:value-of select='address/@addr' /></h3>
   <p>Status: <strong><xsl:value-of select='status/@state' /></strong></p>
   <p>Hostname: <strong><xsl:value-of select='hostnames/hostname/@name' /></strong></p>
  </xsl:if>
  <xsl:apply-templates />
 </div>
</xsl:template>

<xsl:template match="os">
 <p>OS: 
  <xsl:for-each select="osmatch">
  <strong><xsl:value-of select="@name" /></strong><br />
  </xsl:for-each>
 </p>
 <br />
</xsl:template>

<xsl:template match="ports">
 <table>
  <tr><th>Port</th><th>Status</th><th>Protocol</th><th>Service</th></tr>
  <xsl:for-each select="port">
   <!-- Bah fuck I need a table- i fix this as soon as possible -->
   <tr>
    <xsl:if test="state/@state='open'"> 
     <xsl:attribute name="class">tr2</xsl:attribute>
    </xsl:if> 
    <xsl:if test="state/@state != 'open'"> 
     <xsl:attribute name="class">tr1</xsl:attribute>
    </xsl:if>
    <td><xsl:value-of select="@portid " /></td>
    <td><xsl:value-of select="state/@state " /></td>
    <td><xsl:value-of select="@protocol " /></td>
    <td><xsl:value-of select="service/@name" /></td>
   </tr>
  </xsl:for-each>
 </table>
</xsl:template>
</xsl:stylesheet>

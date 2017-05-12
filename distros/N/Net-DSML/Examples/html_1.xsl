<xsl:stylesheet version="1.0"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:template match="/">
    <html>
      <head>
	<title>Results</title>
      </head>
      <body>
	<h1>Results</h1>
	<xsl:for-each select=
	     "soap-env:Envelope/soap-env:Body/batchResponse/searchResponse/searchResultEntry">
	  <h6 >
	    <xsl:value-of select="@dn"/>
	  </h6>
	  <table border="1">
	    <xsl:for-each select="attr">
              <tr>
                <th align="right">
                  <xsl:value-of select="@name"/>
                </th>
                <xsl:for-each select="value">
                  <td align="left">
                    <xsl:value-of select="."/>
                  </td>
                </xsl:for-each>
              </tr>
            </xsl:for-each>
	  </table>
	</xsl:for-each>
      </body>
    </html>
  </xsl:template>
</xsl:stylesheet>

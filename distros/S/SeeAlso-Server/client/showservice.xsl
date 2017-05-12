<?xml version="1.0" encoding="UTF-8"?>
<!--
  SeeAlso service display and test page.
  Version 0.9.01

  Usage: Put this file (showservice.xsl) in a directory together with 
  seealso.js, xmlverbatim.xsl and favicon.ico (optional)
  and let your SeeAlso service point to it in the unAPI format list file.

  Copyright (C) 2007-2010 by Verbundzentrale Goettingen (VZG) and Jakob Voss

  Licensed under the Apache License, Version 2.0 (the "License"); 
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software distributed
  under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
  CONDITIONS OF ANY KIND, either express or implied. See the License for the
  specific language governing permissions and limitations under the License.

  Alternatively, this software may be used under the terms of the 
  GNU Lesser General Public License (LGPL).
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
  xmlns="http://www.w3.org/1999/xhtml"
  xmlns:osd="http://a9.com/-/spec/opensearch/1.1/" 
  xmlns:dc="http://purl.org/dc/elements/1.1/"
  xmlns:dcterms="http://purl.org/dc/terms/"
  xmlns:so="http://ws.gbv.de/seealso/schema/"
>
  <xsl:import href="xmlverbatim.xsl"/>
  <xsl:output method="html" encoding="UTF-8" indent="yes"/>

  <!-- explicit query base -->
  <xsl:param name="seealso-query-base" select="/processing-instruction('seealso-query-base')"/>

  <!-- try to get the Open Search description document -->
  <xsl:param name="osdurl">
    <xsl:value-of select="$seealso-query-base"/>
    <xsl:choose>
      <xsl:when test="not($seealso-query-base)">?</xsl:when>
      <xsl:when test="contains($seealso-query-base,'?')">&amp;</xsl:when>
      <xsl:otherwise>?</xsl:otherwise>
    </xsl:choose>
    <xsl:text>format=opensearchdescription</xsl:text>
  </xsl:param>

  <xsl:param name="beaconurl">
    <xsl:if test="/formats/format[@name='beacon']">
      <xsl:value-of select="$seealso-query-base"/>
      <xsl:choose>
        <xsl:when test="not($seealso-query-base)">?</xsl:when>
        <xsl:when test="contains($seealso-query-base,'?')">&amp;</xsl:when>
        <xsl:otherwise>?</xsl:otherwise>
      </xsl:choose>
      <xsl:text>format=beacon</xsl:text>
    </xsl:if>
  </xsl:param>

  <!-- global variables -->
  <xsl:variable name="osd" select="document($osdurl)"/>
  <xsl:variable name="fullservice" select="namespace-uri($osd/*[1]) = 'http://a9.com/-/spec/opensearch/1.1/'"/>
  <xsl:variable name="name">
    <xsl:apply-templates select="$osd/osd:OpenSearchDescription" mode="name"/>
  </xsl:variable>
  <xsl:variable name="formats" select="/formats/format[not(@name='opensearchdescription' or @name='beacon')]"/>
  <xsl:variable name="moreformats" select="$formats[not(@name='seealso')]"/>

  <!-- locate the other files -->
  <xsl:variable name="xsltpi" select="/processing-instruction('xml-stylesheet')"/>
  <xsl:variable name="clientbase">
    <xsl:call-template name="basepath">
      <xsl:with-param name="string" select="substring-before(substring-after($xsltpi,'href=&quot;'),'&quot;')"/>
    </xsl:call-template>
  </xsl:variable >

  <!-- favicon in the client directory (comment out to skip) -->
  <xsl:param name="favicon"><xsl:value-of select="$clientbase"/>favicon.ico</xsl:param>

  <!-- root -->
  <xsl:template match="/">
    <xsl:apply-templates select="formats"/>
  </xsl:template>
  <xsl:template match="/formats">
    <html>
      <head>
        <xsl:if test="$osd">
          <xsl:attribute name="profile">http://a9.com/-/spec/opensearch/1.1/</xsl:attribute>
          <link rel="search" type="application/opensearchdescription+xml"
                href="{$osdurl}" title="{$name}" />
        </xsl:if>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
        <title>SeeAlso service : <xsl:value-of select="$name"/></title>
        <xsl:if test="$favicon">
          <link rel="shortcut icon" type="image/x-icon" href="{$favicon}" />
        </xsl:if>
        <script src="{$clientbase}seealso.js" type="text/javascript" ></script>
        <style type="text/css">
body, h1, h2, th, td { font-family: sans-serif; }
p, table, .footer { font-size: small; }
table, .code, p { margin: 0em 0.5em 0em; }
table { 
  border-collapse:collapse;
  margin-bottom: 0.5em; 
}
td, th { padding: 4px; }
th { text-align: right; vertical-align: top; }
h2, h2 a { color: #96c458; margin: 1em 0em 0.5em 0em; font-size: 1em; } 
h1 { color: #96c458; font-size: 1.5em; }
h1 a { color: #96c458; }
p { padding-bottom: 0.5em; padding-left: 0.5em; }
pre, .code {
  background: #ddd; 
  border: 1px solid #666;
  padding: 4px;
  margin: 0;
}
#display-styles {
  margin-top: 0.5em;
}
#display {
  background: #fff;
  border: 1px dotted #ddd;
  padding: 4px;
}
.footer {
  border-top: 1px solid #96c458;
  color: #666;
  margin-top: 1em;
  padding: 0.5em;
}
/* xmlverbatim.css */
.xmlverb-default          { color: #333333; background-color: #ffffff;
                            font-family: monospace }
.xmlverb-element-name     { color: #990000 }
.xmlverb-element-nsprefix { color: #666600 }
.xmlverb-attr-name        { color: #660000 }
.xmlverb-attr-content     { color: #000099; font-weight: bold }
.xmlverb-ns-name          { color: #666600 }
.xmlverb-ns-uri           { color: #330099 }
.xmlverb-text             { color: #000000; font-weight: bold }
.xmlverb-comment          { color: #006600; font-style: italic }
.xmlverb-pi-name          { color: #006600; font-style: italic }
.xmlverb-pi-content       { color: #006666; font-style: italic }
        </style>
        <script type="text/javascript">
          var collection = new SeeAlsoCollection();
          var service = new SeeAlsoService("<xsl:value-of select="$seealso-query-base"/>");
          var view = new SeeAlsoUL();
          var currentResponse;
          var currentFormat = "seealso";
          var displayElement;

          function toggleDisplay( element, button ) {
              if ( element.style.display == "none" ) {
                  element.style.display = "";
                  if (button) button.data = "-";
              } else {
                  element.style.display = "none";
                  if (button) button.data = "+";
              }
          }

          function toggleFullResponse(sign) {
              var identifier = document.getElementById('identifier').value;
              var url = service.url;
              url += url.indexOf('?') == -1 ? '?' : '&amp;';
              url += "format=debug&amp;id=" + identifier;
              var iframe = document.getElementById('response-debug-iframe');
              var shortresponse = document.getElementById('response');
              toggleDisplay( iframe, sign.firstChild );
              if (iframe.style.display != "none") {
                  shortresponse.style.display = "none";
                  iframe.src = url;
              } else {
                  shortresponse.style.display = "";
              }
          }

          function lookup() {
              var identifier = document.getElementById('identifier').value;
              var format = currentFormat;

              /* construct the query URL */
              var url = service.url;
              url += url.indexOf('?') == -1 ? '?' : '&amp;';
              url += "format=" + format + "&amp;id=" + identifier;
              var a = document.getElementById('query-url');
              a.setAttribute("href",url);
              a.innerHTML = "";
              a.appendChild(document.createTextNode(url));

              if (format == "seealso") {
                  document.getElementById('response').style.display = "";
                  document.getElementById('response-debug-iframe').style.display = "none";
                  url += "&amp;callback=?";
                  service.query( identifier, function(response) {
                      currentResponse = response;
                      var json = response.toJSON();
                      var r = document.getElementById('response');
                      r.innerHTML = "";
                      r.appendChild(document.createTextNode(json));
                      if (displayElement) view.display(displayElement,response);
                  });
              } else {
                  var identifier = document.getElementById('identifier').value;
                  var iframe = document.getElementById('response-other-iframe');
                  iframe.src = url;
              }
          }
          function changeView(select) {
              var viewName = select.options[select.options.selectedIndex].value;
              view = collection.views[viewName];
              if (!view) view = new SeeAlsoUL();
              if (currentResponse) view.display(displayElement,currentResponse);
          }
          function init() {
              displayElement = document.getElementById('display');
              var displaystyles = document.getElementById('display-styles');
              for(var viewName in collection.views) {
                  var option = document.createElement("option");
                  option.appendChild(document.createTextNode(viewName));
                  if (viewName == "seealso-ul") {
                      option.setAttribute("selected","selected");
                  }
                  displaystyles.appendChild(option);
              }
              displaystyles.parentNode.style.display = "block";
              selectFormat("seealso"); // TODO: this could fail
          }
          function selectFormat(format) {
              if (format=="seealso") {
                  document.getElementById('displayrow').style.display="";
                  document.getElementById('seealso-response').style.display="";
                  document.getElementById('other-response').style.display="none";
              } else {
                  document.getElementById('displayrow').style.display="none";
                  document.getElementById('seealso-response').style.display="none";
                  document.getElementById('other-response').style.display="";
              }
              document.getElementById('format-'+currentFormat).style.fontWeight = "normal";
              document.getElementById('format-'+format).style.fontWeight = "bold";
              currentFormat = format;
              lookup();
          }
          function changeExample(select) {
              var value = select.options[select.options.selectedIndex].value;
              document.getElementById("identifier").value = value;
              lookup();
          }
         </script> 
      </head>
      <body onload="init();">
        <xsl:variable name="title">
          <xsl:choose>
            <xsl:when test="string-length($name) &gt; 0"><xsl:value-of select="$name"/></xsl:when>
            <xsl:otherwise>SeeAlso service</xsl:otherwise>
          </xsl:choose>
        </xsl:variable>
        <h1>
          <xsl:choose>
            <xsl:when test="$seealso-query-base">
              <a href="{$seealso-query-base}"><xsl:value-of select="$title"/></a>
            </xsl:when>
            <xsl:otherwise><xsl:value-of select="$title"/></xsl:otherwise>
          </xsl:choose>
        </h1>
        <xsl:if test="$osd/osd:OpenSearchDescription/osd:Description">
            <p><xsl:value-of select="$osd/osd:OpenSearchDescription/osd:Description"/></p>
        </xsl:if>
        <xsl:choose>
          <xsl:when test="$fullservice">
            <xsl:call-template name="demo">
              <xsl:with-param name="osd" select="$osd/osd:OpenSearchDescription"/>
            </xsl:call-template>
            <h2>About this SeeAlso Webservice</h2>
            <xsl:call-template name="intro"/>
            <xsl:call-template name="about">
              <xsl:with-param name="osd" select="$osd/osd:OpenSearchDescription"/>
            </xsl:call-template>
            <h2 id='osd' name='osd'>OpenSearch description document</h2>
            <p>
            This document is returned at <a href="{$osdurl}"><xsl:value-of select="$osdurl"/></a>
            to describe the <xsl:value-of select="$name"/> service.
            </p>
            <div class="code">
              <xsl:apply-templates select="$osd" mode="xmlverb" />
            </div>
          </xsl:when>
          <xsl:otherwise>
            <xsl:call-template name="demo"/>
            <h2>About this SeeAlso Webservice</h2>
            <xsl:call-template name="intro"/>
          </xsl:otherwise>
        </xsl:choose>
        <xsl:if test="name(/*[1]) = 'formats'">
          <h2 id='formats'>unAPI format list</h2>
          <div class="code" id='formats'>
            <xsl:apply-templates select="/" mode="xmlverb" />
          </div>
        </xsl:if>
        <div class="footer">This document has automatically been generated based 
        on the services' <a href="{$osdurl}">OpenSearch description document</a>
        (see <a href="http://www.opensearch.org/">OpenSearch.org</a>).
        </div>
        <!-- TODO: Show version number of the SeeAlso JavaScript library -->
      </body>
    </html>
  </xsl:template>

  <xsl:template match="osd:OpenSearchDescription" mode="name">
    <xsl:choose>
      <xsl:when test="osd:ShortName">
        <xsl:value-of select="osd:ShortName"/>
      </xsl:when>
      <xsl:otherwise>
        <i>unnamed SeeAlso web service</i>
      </xsl:otherwise>
    </xsl:choose>
  </xsl:template>

<!-- short information -->
<xsl:template name="intro">
  <p>
    This is the base URL of a 
    <b>
    <xsl:choose>
      <xsl:when test="$fullservice">SeeAlso Full</xsl:when>
      <xsl:otherwise>SeeAlso Simple</xsl:otherwise>
    </xsl:choose>
    </b>
    web service for retrieving links related to a given identifier.
    The service provides an <a href="http://unapi.info">unAPI</a> format list that
    includes the <em>seealso</em> response format
    (see <a href="http://www.gbv.de/wikis/cls/SeeAlso_Simple_Specification">SeeAlso Simple Specification</a>).
    You can test the service by typing in an identifier in the query field above.
    In practise this web service should not be queried by hand but included in another web page or application.
  </p>
  <p>
    If you query in <tt>seealso</tt> JSON format, you can add a <tt>callback</tt> parameter to the query URL.
    The JSON response is then wrapped in in parentheses and a function name of your choice.
    Callbacks are particularly useful for use with web service requests in client-side JavaScript, but they
    also involve security risks.
  </p>
</xsl:template>

<!-- Show BaseURL, URL template and additional metadata in the OpenSearch description document -->
<xsl:template name="about">
  <xsl:param name="osd"/>
  <table>
    <xsl:for-each select="$osd/*">
      <xsl:variable name="localname" select="local-name(.)"/>
      <xsl:variable name="fullname" select="name(.)"/>
      <xsl:variable name="namespace" select="namespace-uri(.)"/>
      <xsl:if test="$localname != 'Query' and $localname!='Url' and $localname != 'ShortName' and $localname != 'Description'">
        <tr>
          <th><xsl:value-of select="$localname"/></th>
          <td><xsl:value-of select="normalize-space(.)"/></td>
        </tr>
      </xsl:if>
    </xsl:for-each>
    <tr>
      <th>URL template</th>
      <td><xsl:value-of select="$osd/osd:Url[@type='text/javascript'][1]/@template"/></td>
    </tr>
    <xsl:if test="$moreformats">
      <tr>
        <th>unAPI formats</th>
        <td>
          <xsl:for-each select="$formats">
            <xsl:if test="position() &gt; 1"><br/></xsl:if>
            <xsl:if test="@docs">
              <a href="{@docs}"><xsl:value-of select="@name"/></a>
            </xsl:if>
            <xsl:if test="not(@docs)">
              <xsl:value-of select="@name"/>
            </xsl:if>
            <xsl:if test="@type"> (<xsl:value-of select="@type"/>)</xsl:if>
          </xsl:for-each>
        </td>
      </tr>
    </xsl:if>
    <xsl:if test="$beaconurl">
      <tr>
        <th>Download</th>
        <td>You can also <a href="{$beaconurl}">download a full dump</a> in BEACON format.</td>
      </tr>
    </xsl:if>
    <!-- TODO: add information about additional fields (if any) -->
  </table>
</xsl:template>

<xsl:template name="demo">
  <xsl:param name="osd"/>
  <xsl:variable name="examples" select="$osd/osd:Query[@role='example'][@searchTerms]"/>
  <form>
    <p>
      <input type="text" id="identifier" onkeyup="lookup();" size="50" value="{/formats/@id}"/>
      <xsl:if test="$osd and $examples">
      <xsl:text> try for instance </xsl:text>
      <xsl:if test="count($examples) &gt;= 3">
            <select name="examples" onchange="changeExample(this);">
            <option value="" />
            <xsl:for-each select="$examples">
                <option value="{@searchTerms}">
                <xsl:value-of select="@searchTerms"/>
                </option>
            </xsl:for-each>
            </select>
      </xsl:if>
      <xsl:if test="count($examples) &lt; 3">
            <xsl:for-each select="$examples">
            <xsl:if test="position() &gt; 1 and position() &lt; 4">, </xsl:if>
            <xsl:if test="position() &lt; 4">
                <tt style="text-decoration:underline" onclick='document.getElementById("identifier").value="{@searchTerms}";lookup();'>
                    <xsl:value-of select="@searchTerms"/>
                </tt>
            </xsl:if>
            </xsl:for-each>
          </xsl:if>
      </xsl:if>
    </p>
    <p><a id='query-url' href=''></a></p>
      <xsl:if test="$moreformats">
        <p>
          format = 
          <xsl:for-each select="$formats">
            <xsl:if test="position() &gt; 1"> | </xsl:if>
            <span id="format-{@name}" onclick="selectFormat('{@name}');" title="{@type}">
              <xsl:value-of select="@name"/>
            </span>
          </xsl:for-each>
        </p>
      </xsl:if>
    <h2>Response</h2>
      <p>
          <span id="seealso-response">
            <small style="float:right;">[<span onclick="toggleFullResponse(this);">+</span>]</small>
            <pre id='response'></pre>
            <!-- IE does not like empty tag iframe! -->
            <iframe id="response-debug-iframe" width="90%" name="response-debug-iframe" src="" scrolling="auto" style="display:none;" class="code"></iframe>
          </span>
          <span id="other-response" style="display:none">
            <iframe id="response-other-iframe" width="90%" name="response-other-iframe" src="" scrolling="auto" class="code"></iframe>
          </span>
      </p>
    <table id='demo'>
      <!--tr>
        <td colspan="2">
          <span id="seealso-response">
            <small style="float:right;">[<span onclick="toggleFullResponse(this);">+</span>]</small>
            <pre id='response'></pre>
            <iframe id="response-debug-iframe" width="90%" name="response-debug-iframe" src="" scrolling="auto" style="display:none;" class="code" ></iframe>
          </span>
          <span id="other-response" style="display:none">
            <iframe id="response-other-iframe" width="90%" name="response-other-iframe" src="" scrolling="auto" class="code"></iframe>
          </span>
        </td>
      </tr-->
      <tr id="displayrow">
        <th>
          <div style="display:none;">display as
            <select id='display-styles' onchange="changeView(this);">
            </select>
          </div>
        </th>
        <td>
          <div id='display'></div>
        </td>
      </tr>
    </table>
  </form>
</xsl:template>

<!-- reusable replace-string function -->
<xsl:template name="replace-string">
  <xsl:param name="text"/>
  <xsl:param name="from"/>
  <xsl:param name="to"/>  
  <xsl:choose>
    <xsl:when test="contains($text, $from)">
      <xsl:variable name="before" select="substring-before($text, $from)"/>
      <xsl:variable name="after" select="substring-after($text, $from)"/>
      <xsl:variable name="prefix" select="concat($before, $to)"/>
      <xsl:value-of select="$before"/>
      <xsl:value-of select="$to"/>
      <xsl:call-template name="replace-string">
        <xsl:with-param name="text" select="$after"/>
        <xsl:with-param name="from" select="$from"/>
        <xsl:with-param name="to" select="$to"/>
      </xsl:call-template>
    </xsl:when> 
    <xsl:otherwise>
      <xsl:value-of select="$text"/>  
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<!-- will work as long as this script is not served via an URL with '/' in the query part -->
<xsl:template name="basepath">
  <xsl:param name="string"/>
  <xsl:param name="pos" select="1"/>
  <xsl:choose>
    <xsl:when test="contains(substring($string,$pos),'/')">
      <xsl:call-template name="basepath">
        <xsl:with-param name="string" select="$string"/>
        <xsl:with-param name="pos" select="$pos + 1"/>
      </xsl:call-template>
    </xsl:when>
    <xsl:when test="$pos &gt; 1">
      <xsl:value-of select="substring($string,1,$pos - 1)"/>
    </xsl:when>
  </xsl:choose>
</xsl:template>

</xsl:stylesheet>

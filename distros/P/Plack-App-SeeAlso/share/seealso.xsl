<?xml version="1.0" encoding="UTF-8"?>
<!--
    SeeAlso service display and test page.
    Version 0.9.2

    Usage: Put this file (seealso.xsl) in a directory together with seealso.js,
    and seealso.css (and optionally favicon.ico) and let your SeeAlso service
    point to it in the unAPI format list file.

    Copyright (C) 2007-2012 by Verbundzentrale Goettingen (VZG) and Jakob Voss

    Licensed under the Apache License, Version 2.0 (the "License"); 
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0
    Unless required by applicable law or agreed to in writing, software distributed
    under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR 
    CONDITIONS OF ANY KIND, either express or implied. See the License for the
    specific language governing permissions and limitations under the License.

    Alternatively, this software may be used under the terms of the 
    GNU Lesser General Public License (LGPL).

    This XSLT script contains a modified version of `xmlverbatim.xsl`, an XML to 
    HTML Verbatim Formatter with Syntax Highlighting, GPL 2002 by Oliver Becker.
-->
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0"
    xmlns="http://www.w3.org/1999/xhtml"
    xmlns:osd="http://a9.com/-/spec/opensearch/1.1/" 
    xmlns:dc="http://purl.org/dc/elements/1.1/"
    xmlns:dcterms="http://purl.org/dc/terms/"
>
  <!--xsl:output method="xml" indent="yes" 
        doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
        doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" /-->

  <xsl:output method="html" indent="no" />

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

  <!-- TODO -->
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
  </xsl:variable>

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
        <script src="{$clientbase}seealso.js" type="text/javascript" ></script>
        <link rel="stylesheet" type="text/css" href="seealso.css" />
        <script type="text/javascript">

// helper methods
function getDOM(id) { return document.getElementById(id); }
function toggleDisplay (e,b) { 
    var mode = (e.style.display == "none");
    e.style.display = (mode ? "block" : "none");
    b.data = "&#xA0;" + (mode ? "-" : "+" ) + "&#xA0;";
}

var collection = new SeeAlsoCollection();
var service = new SeeAlsoService("<xsl:value-of select="$seealso-query-base"/>");
var view = new SeeAlsoUL();
var currentResponse;
var currentFormat = "seealso";

function toggleResponse(sign) {
    var identifier = getDOM('identifier').value;
    var url = service.url;
    url += url.indexOf('?') == -1 ? '?' : '&amp;';
    url += "format=seealso&amp;id=" + identifier;
    var iframe = getDOM('response-debug-iframe');
    var shortresponse = getDOM('response');
    toggleDisplay( iframe, sign.firstChild );
    if (iframe.style.display != "none") {
        shortresponse.style.display = "none";
        iframe.src = url;
    } else {
        shortresponse.style.display = "";
    }
}

function lookup() {
    var identifier = getDOM('identifier').value;
    var format = currentFormat;

    /* construct the query URL */
    var url = service.url;
    url += url.indexOf('?') == -1 ? '?' : '&amp;';
    url += "format=" + format + "&amp;id=" + identifier;
    var a = getDOM('query-url');
    a.setAttribute("href",url);
    a.innerHTML = "";
    a.appendChild(document.createTextNode(url));

    if (format == "seealso") {
      getDOM('response').style.display = "";
      getDOM('response-debug-iframe').style.display = "none";
      url += "&amp;callback=?";
      service.query( identifier, function(response) {
          currentResponse = response;
          var json = response.toJSON();
          var r = getDOM('response');
          r.innerHTML = "";
          r.appendChild(document.createTextNode(json));
          if (getDOM('display')) view.display(getDOM('display'),response);
      });
    } else {
      var identifier = getDOM('identifier').value;
      var iframe = getDOM('response-other-iframe');
      iframe.src = url;
    }
}

function changeView(select) {
    var viewName = select.options[select.options.selectedIndex].value;
    view = collection.views[viewName];
    if (!view) view = new SeeAlsoUL();
    if (currentResponse) view.display(getDOM('display'),currentResponse);
}

function selectFormat(format) {
  if (format=="seealso") {
      getDOM('displayrow').style.display="";
      getDOM('seealso-response').style.display="";
      getDOM('other-response').style.display="none";
  } else {
      getDOM('displayrow').style.display="none";
      getDOM('seealso-response').style.display="none";
      getDOM('other-response').style.display="";
  }
    var e = getDOM('format-'+currentFormat);
    if (e) { cur.style.fontWeight = "normal"; }
    e = getDOM('format-'+format);
    if (e) { e.style.fontWeight = "bold"; }
    currentFormat = format;
    lookup();
}
function changeExample(select) {
    var value = select.options[select.options.selectedIndex].value;
    document.getElementById("identifier").value = value;
    lookup();
}

function init() {
    var displaystyles = getDOM('display-styles');
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
    If you query for <tt>format=seealso</tt>, you can also add a <tt>callback</tt> parameter to the query URL (JSONP).
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
      <td><code><xsl:value-of select="$osd/osd:Url[@type='text/javascript'][1]/@template"/></code></td>
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
    <xsl:if test="string-length($beaconurl) &gt; 0">
      <tr>
        <th>Download:</th>
        <td>You can also <a href="{$beaconurl}">download a full dump</a> in BEACON format.</td>
      </tr>
    </xsl:if>
    <!-- TODO: add information about additional fields (if any) -->
  </table>
</xsl:template>

<xsl:template name="demo">
  <xsl:param name="osd"/>
  <h2>Query</h2>
  <form>
    <p>
      <label for="identifier">id=</label>
      <input type="text" id="identifier" onkeyup="lookup();" size="50" value="{/formats/@id}"/>
      <xsl:if test="$osd">
        <xsl:variable name="examples" select="$osd/osd:Query[@role='example'][@searchTerms]"/>
        <xsl:if test="$examples">
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
    <h2>Response&#xA0;&#xA0;&#xA0;[ <span onclick="toggleResponse(this);">&#xA0;+&#xA0;</span> ]</h2>
      <p>
          <span id="seealso-response">
            <pre id='response'></pre>
            <!-- IE does not like empty tag iframe! -->
            <iframe id="response-debug-iframe" width="90%" name="response-debug-iframe" src="" scrolling="auto" style="display:none;" class="code"></iframe>
          </span>
          <span id="other-response" style="display:none">
            <iframe id="response-other-iframe" width="90%" name="response-other-iframe" src="" scrolling="auto" class="code"></iframe>
          </span>
      </p>
    <table id='demo'>
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


   <!-- =========================================================== -->
   <!--                xmlverbatim.xsl (simplified)                 -->
   <!-- =========================================================== -->

   <!-- root -->
   <xsl:template match="/" mode="xmlverb">
      <pre class="xmlverb-default">
         <xsl:apply-templates mode="xmlverb"/>
      </pre>
   </xsl:template>

   <!-- element nodes -->
   <xsl:template match="*" mode="xmlverb">
      <xsl:param name="indent" select="''" />
      <xsl:param name="indent-increment" select="'&#xA0;&#xA0;&#xA0;'" />
      <xsl:value-of select="$indent" />
      <xsl:text>&lt;</xsl:text>
      <xsl:variable name="ns-prefix" select="substring-before(name(),':')" />
      <xsl:if test="$ns-prefix != ''">
         <span class="xmlverb-element-nsprefix">
            <xsl:value-of select="$ns-prefix"/>
         </span>
         <xsl:text>:</xsl:text>
      </xsl:if>
      <span class="xmlverb-element-name">
         <xsl:value-of select="local-name()"/>
      </span>
      <xsl:variable name="pns" select="../namespace::*"/>
      <xsl:if test="$pns[name()=''] and not(namespace::*[name()=''])">
         <span class="xmlverb-ns-name">
            <xsl:text> xmlns</xsl:text>
         </span>
         <xsl:text>=&quot;&quot;</xsl:text>
      </xsl:if>
      <xsl:for-each select="namespace::*">
         <xsl:if test="not($pns[name()=name(current()) and 
                           .=current()])">
            <xsl:call-template name="xmlverb-ns" />
         </xsl:if>
      </xsl:for-each>
      <xsl:for-each select="@*">
         <xsl:call-template name="xmlverb-attrs" />
      </xsl:for-each>
      <xsl:choose>
         <xsl:when test="node()">
            <xsl:text>&gt;</xsl:text>
            <xsl:if test="* or processing-instruction() or comment()">
              <xsl:text>&#xA;</xsl:text>
            </xsl:if>
            <xsl:apply-templates mode="xmlverb">
              <xsl:with-param name="indent"
                              select="concat($indent, $indent-increment)"/>
              <xsl:with-param name="indent-increment"
                              select="$indent-increment"/>
            </xsl:apply-templates>
            <xsl:text>&lt;/</xsl:text>
            <xsl:if test="$ns-prefix != ''">
               <span class="xmlverb-element-nsprefix">
                  <xsl:value-of select="$ns-prefix"/>
               </span>
               <xsl:text>:</xsl:text>
            </xsl:if>
            <span class="xmlverb-element-name">
               <xsl:value-of select="local-name()"/>
            </span>
            <xsl:text>&gt;</xsl:text>
         </xsl:when>
         <xsl:otherwise>
            <xsl:text> /&gt;</xsl:text>
         </xsl:otherwise>
      </xsl:choose>
      <xsl:text>&#xA;</xsl:text>
   </xsl:template>

   <!-- attribute nodes -->
   <xsl:template name="xmlverb-attrs">
      <xsl:text> </xsl:text>
      <span class="xmlverb-attr-name">
         <xsl:value-of select="name()"/>
      </span>
      <xsl:text>=&quot;</xsl:text>
      <span class="xmlverb-attr-content">
         <xsl:call-template name="html-replace-entities">
            <xsl:with-param name="text" select="normalize-space(.)" />
            <xsl:with-param name="attrs" select="true()" />
         </xsl:call-template>
      </span>
      <xsl:text>&quot;</xsl:text>
   </xsl:template>

   <!-- namespace nodes -->
   <xsl:template name="xmlverb-ns">
      <xsl:if test="name()!='xml'">
         <span class="xmlverb-ns-name">
            <xsl:text> xmlns</xsl:text>
            <xsl:if test="name()!=''">
               <xsl:text>:</xsl:text>
            </xsl:if>
            <xsl:value-of select="name()"/>
         </span>
         <xsl:text>=&quot;</xsl:text>
         <span class="xmlverb-ns-uri">
            <xsl:value-of select="."/>
         </span>
         <xsl:text>&quot;</xsl:text>
      </xsl:if>
   </xsl:template>

   <!-- text nodes -->
   <xsl:template match="text()" mode="xmlverb">
      <span class="xmlverb-text">
         <xsl:call-template name="preformatted-output">
            <xsl:with-param name="text">
               <xsl:call-template name="html-replace-entities">
                  <xsl:with-param name="text" select="normalize-space(.)" />
               </xsl:call-template>
            </xsl:with-param>
         </xsl:call-template>
      </span>
   </xsl:template>

   <!-- comments -->
   <xsl:template match="comment()" mode="xmlverb">
      <xsl:text>&lt;!--</xsl:text>
      <span class="xmlverb-comment">
         <xsl:call-template name="preformatted-output">
            <xsl:with-param name="text" select="." />
         </xsl:call-template>
      </span>
      <xsl:text>--&gt;&#xA;</xsl:text>
   </xsl:template>

   <!-- processing instructions -->
   <xsl:template match="processing-instruction()" mode="xmlverb">
      <xsl:text>&lt;?</xsl:text>
      <span class="xmlverb-pi-name">
         <xsl:value-of select="name()"/>
      </span>
      <xsl:if test=".!=''">
         <xsl:text> </xsl:text>
         <span class="xmlverb-pi-content">
            <xsl:value-of select="."/>
         </span>
      </xsl:if>
      <xsl:text>?&gt;&#xA;</xsl:text>
   </xsl:template>


   <!-- =========================================================== -->
   <!--                    Procedures / Functions                   -->
   <!-- =========================================================== -->

   <!-- generate entities by replacing &, ", < and > in $text -->
   <xsl:template name="html-replace-entities">
      <xsl:param name="text" />
      <xsl:param name="attrs" />
      <xsl:variable name="tmp">
         <xsl:call-template name="replace-substring">
            <xsl:with-param name="from" select="'&gt;'" />
            <xsl:with-param name="to" select="'&amp;gt;'" />
            <xsl:with-param name="value">
               <xsl:call-template name="replace-substring">
                  <xsl:with-param name="from" select="'&lt;'" />
                  <xsl:with-param name="to" select="'&amp;lt;'" />
                  <xsl:with-param name="value">
                     <xsl:call-template name="replace-substring">
                        <xsl:with-param name="from" 
                                        select="'&amp;'" />
                        <xsl:with-param name="to" 
                                        select="'&amp;amp;'" />
                        <xsl:with-param name="value" 
                                        select="$text" />
                     </xsl:call-template>
                  </xsl:with-param>
               </xsl:call-template>
            </xsl:with-param>
         </xsl:call-template>
      </xsl:variable>
      <xsl:choose>
         <!-- $text is an attribute value -->
         <xsl:when test="$attrs">
            <xsl:call-template name="replace-substring">
               <xsl:with-param name="from" select="'&#xA;'" />
               <xsl:with-param name="to" select="'&amp;#xA;'" />
               <xsl:with-param name="value">
                  <xsl:call-template name="replace-substring">
                     <xsl:with-param name="from" 
                                     select="'&quot;'" />
                     <xsl:with-param name="to" 
                                     select="'&amp;quot;'" />
                     <xsl:with-param name="value" select="$tmp" />
                  </xsl:call-template>
               </xsl:with-param>
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$tmp" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- replace in $value substring $from with $to -->
   <xsl:template name="replace-substring">
      <xsl:param name="value" />
      <xsl:param name="from" />
      <xsl:param name="to" />
      <xsl:choose>
         <xsl:when test="contains($value,$from)">
            <xsl:value-of select="substring-before($value,$from)" />
            <xsl:value-of select="$to" />
            <xsl:call-template name="replace-substring">
               <xsl:with-param name="value" 
                               select="substring-after($value,$from)" />
               <xsl:with-param name="from" select="$from" />
               <xsl:with-param name="to" select="$to" />
            </xsl:call-template>
         </xsl:when>
         <xsl:otherwise>
            <xsl:value-of select="$value" />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>

   <!-- preformatted output: space as &nbsp;, tab as 8 &nbsp; -->
   <xsl:template name="preformatted-output">
      <xsl:param name="text" />
      <xsl:call-template name="replace-substring">
         <xsl:with-param name="value"
                         select="translate($text,' ','&#xA0;')" />
         <xsl:with-param name="from" select="'&#9;'" />
         <xsl:with-param name="to" 
                         select="'&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;&#xA0;'" />
      </xsl:call-template>
   </xsl:template>

</xsl:stylesheet>

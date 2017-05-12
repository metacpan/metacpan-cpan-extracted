#include<colorer/parsers/TextParserImpl.h>
#include<stdio.h>

/////////////////////////////////////////////////////////////////////////
// TextParserImpl
TextParserImpl::TextParserImpl()
{
  cache = new ParseCache();
  clearCache();
  lineSource = null;
  regionHandler = null;
  picked = null;
  baseScheme = null;
}
TextParserImpl::~TextParserImpl()
{
  clearCache();
  delete cache;
}

void TextParserImpl::setFileType(FileType *type){
  baseScheme = null;
  if (type != null){
    baseScheme = (SchemeImpl*)(type->getBaseScheme());
  };
  clearCache();
};

void TextParserImpl::setLineSource(LineSource *lh){
  lineSource = lh;
};
void TextParserImpl::setRegionHandler(RegionHandler *rh){
  regionHandler = rh;
};




int TextParserImpl::parse(int from, int num)
{
  int i;
  parsing = true;
  breakParsing = false;
  cacheHack = true;
  schemeStart = -1;
  gx = 0;
  gy = from;
  gy2 = from+num;
  clearLine = -1;
  vtlist = new VTList();

  if (regionHandler == null) return from;
  if (lineSource == null) return from;
  if (baseScheme == null) return from;
  lineSource->startJob(from);
  regionHandler->startParsing(from);

  cache->scheme = baseScheme;
  parent = cache->searchLine(from, &forward);
  cachedParent = parent;
  cachedForward = forward;
  cachedLineNo = from;

  do{
    if (!forward){
      if (!parent) return from;
      delete parent->children;
      parent->children = null;
    }else{
      delete forward->next;
      forward->next = null;
    };
    baseScheme = parent->scheme;

    if (parent != cache){
      vtlist->restore(parent->vcache);
      parent->clender->end->setBackTrace(parent->backLine, &parent->matchstart);
      colorize(parent->clender->end, parent->clender->lowContentPriority);
      vtlist->clear();
    }else{
      colorize(null, false);
    };

    if (parent != cache){
      parent->eline = gy;
    };
    if (parent != cache && gy < gy2){
      for (i = 0; i < matchend.cMatch; i++)
        addRegion(gy, matchend.s[i], matchend.e[i], parent->clender->regione[i]);
      for (i = 0; i < matchend.cnMatch; i++)
        addRegion(gy, matchend.ns[i], matchend.ne[i], parent->clender->regionen[i]);
      leaveScheme(gy, matchend.s[0], matchend.e[0], parent->clender->region);
    };
    gx = matchend.e[0];

    forward = parent;
    parent = parent->parent;
  }while(parent);
  regionHandler->endParsing(endLine);
  lineSource->endJob(endLine);
  delete vtlist;
  return endLine;
};

void TextParserImpl::clearCache()
{
  delete cache->children;
  delete cache->backLine;
  cache->backLine = null;
  cache->sline = 0;
  cache->eline = 0x7FFFFFF;
  cache->children = cache->parent = cache->next = null;
};
void TextParserImpl::breakParse()
{
  breakParsing = true;
};

void TextParserImpl::addRegion(int lno, int sx, int ex, const Region* region){
  if (sx == -1 || region == null) return;
  regionHandler->addRegion(lno, str, sx, ex, region);
};
void TextParserImpl::enterScheme(int lno, int sx, int ex, const Region* region){
  regionHandler->enterScheme(lno, str, sx, ex, region, baseScheme);
};
void TextParserImpl::leaveScheme(int lno, int sx, int ex, const Region* region){
  regionHandler->leaveScheme(lno, str, sx, ex, region, baseScheme);
  if (region != null) picked = region;
};


void TextParserImpl::hack4regions(ParseCache *ch)
{
  if (!ch->parent || ch == cache) return;
  hack4regions(ch->parent);
  enterScheme(gy, 0, 0, ch->clender->region);
  return;
};

int TextParserImpl::searchKW(const SchemeNode *node, int no, int lowlen, int hilen)
{
  if (!node->kwList->num) return MATCH_NOTHING;

  if (node->kwList->minKeywordLength+gx > lowlen) return MATCH_NOTHING;
  if (gx < lowlen && !node->kwList->firstChar->inClass((*str)[gx])) return MATCH_NOTHING;

  int left = 0;
  int right = node->kwList->num;
  while(true){
    int pos = left + (right-left)/2;
    int kwlen = node->kwList->kwList[pos].keyword->length();
    if (lowlen < gx+kwlen) kwlen = lowlen-gx;

    int cr;
    if (node->kwList->matchCase)
      cr = node->kwList->kwList[pos].keyword->compareTo(DString(*str, gx, kwlen));
    else
      cr = node->kwList->kwList[pos].keyword->compareToIgnoreCase(DString(*str, gx, kwlen));

    if (cr == 0 && right-left == 1){
      bool badbound = false;
      if (!node->kwList->kwList[pos].isSymbol){
        if (!node->worddiv){
          if (gx && (Character::isLetterOrDigit((*str)[gx-1]) || (*str)[gx-1] == '_')) badbound = true;
          if (gx + kwlen < lowlen &&
          (Character::isLetterOrDigit((*str)[gx + kwlen]) || (*str)[gx + kwlen] == '_')) badbound = true;
        }else{
        // custom check for word bound
          if (gx && !node->worddiv->inClass((*str)[gx-1])) badbound = true;
          if (gx + kwlen < lowlen &&
            !node->worddiv->inClass((*str)[gx + kwlen])) badbound = true;
        };
      };
      if (!badbound){
        addRegion(gy, gx, gx + kwlen, node->kwList->kwList[pos].region);
        gx += kwlen;
        return MATCH_RE;
      };
    };
    if (right-left == 1){
      left = node->kwList->kwList[pos].ssShorter;
      if (left != -1){
        right = left+1;
        continue;
      };
      break;
    };
    if (cr == 1) right = pos;
    if (cr == 0 || cr == -1) left = pos;
  };
  return MATCH_NOTHING;
};

int TextParserImpl::searchRE(SchemeImpl *cscheme, int no, int lowLen, int hiLen)
{
int i, re_result;
SchemeImpl *ssubst = null;
SMatches match;
ParseCache *OldCacheF = null;
ParseCache *OldCacheP = null;
ParseCache *ResF = null;
ParseCache *ResP = null;

  if (!cscheme) return MATCH_NOTHING;
  for(int idx = 0; idx < cscheme->nodes.size(); idx++){
    SchemeNode *schemeNode = cscheme->nodes.elementAt(idx);
    switch(schemeNode->type){
      case SNT_INHERIT:
        if (!schemeNode->scheme) break;
        ssubst = vtlist->pushvirt(schemeNode->scheme);
        if (!ssubst){
          bool b = vtlist->push(schemeNode);
          re_result = searchRE(schemeNode->scheme, no, lowLen, hiLen);
          if (b) vtlist->pop();
        }else{
          re_result = searchRE(ssubst, no, lowLen, hiLen);
          vtlist->popvirt();
        };
        if (re_result != MATCH_NOTHING) return re_result;
        break;

      case SNT_KEYWORDS:
        if (searchKW(schemeNode, no, lowLen, hiLen) == MATCH_RE) return MATCH_RE;
        break;

      case SNT_RE:
        if (!schemeNode->start->parse(str, gx, schemeNode->lowPriority?lowLen:hiLen, &match, schemeStart))
          break;
        for (i = 0; i < match.cMatch; i++)
          addRegion(gy, match.s[i], match.e[i], schemeNode->regions[i]);
        for (i = 0; i < match.cnMatch; i++)
          addRegion(gy, match.ns[i], match.ne[i], schemeNode->regionsn[i]);

        // skips regexp if it has zero length
        if (match.e[0] == match.s[0]) break;
        gx = match.e[0];
        return MATCH_RE;

      case SNT_SCHEME:{
        if (!schemeNode->scheme) break;
        if (!schemeNode->start->parse(str, gx,
             schemeNode->lowPriority?lowLen:hiLen, &match, schemeStart)) break;

        gx = match.e[0];
        ssubst = vtlist->pushvirt(schemeNode->scheme);
        if (!ssubst) ssubst = schemeNode->scheme;

        if (parsing){
          ResF = forward;
          ResP = parent;
          if (forward){
            forward->next = new ParseCache;
            OldCacheF = forward->next;
            OldCacheP = parent?parent:forward->parent;
            parent = forward->next;
            forward = null;
          }else{
            forward = new ParseCache;
            parent->children = forward;
            OldCacheF = forward;
            OldCacheP = parent;
            parent = forward;
            forward = null;
          };
          OldCacheF->parent = OldCacheP;
          OldCacheF->sline = gy+1;
          OldCacheF->eline = 0x7FFFFFFF;
          OldCacheF->scheme = ssubst;
          OldCacheF->matchstart = match;
          OldCacheF->clender = schemeNode;
          OldCacheF->backLine = new SString(str);
        };

        int ogy = gy;

        SchemeImpl *o_scheme = baseScheme;
        int o_schemeStart = schemeStart;
        SMatches o_matchend = matchend;
        SMatches *o_match;
        DString *o_str;
        schemeNode->end->getBackTrace((const String**)&o_str, &o_match);

        baseScheme = ssubst;
        schemeStart = gx;
        schemeNode->end->setBackTrace(OldCacheF->backLine, &match);

        enterScheme(no, match.s[0], match.e[0], schemeNode->region);
        for (i = 0; i < match.cMatch; i++)
          addRegion(no, match.s[i], match.e[i], schemeNode->regions[i]);
        for (i = 0; i < match.cnMatch; i++)
          addRegion(no, match.ns[i], match.ne[i], schemeNode->regionsn[i]);

        colorize(schemeNode->end, schemeNode->lowContentPriority);

        if (gy < gy2){
          for (i = 0; i < matchend.cMatch; i++)
            addRegion(gy, matchend.s[i], matchend.e[i], schemeNode->regione[i]);
          for (i = 0; i < matchend.cnMatch; i++)
            addRegion(gy, matchend.ns[i], matchend.ne[i], schemeNode->regionen[i]);
          leaveScheme(gy, matchend.s[0], matchend.e[0], schemeNode->region);
        };
        gx = matchend.e[0];

        schemeNode->end->setBackTrace(o_str, o_match);
        matchend = o_matchend;
        schemeStart = o_schemeStart;
        baseScheme = o_scheme;

        if (parsing){
          if (ogy == gy){
            delete OldCacheF;
            if (ResF) ResF->next = null;
            else ResP->children = null;
            forward = ResF;
            parent = ResP;
          }else{
            OldCacheF->eline = gy;
            OldCacheF->vcache = vtlist->store();
            forward = OldCacheF;
            parent = OldCacheP;
          };
        };
        if (ssubst != schemeNode->scheme) vtlist->popvirt();
        return MATCH_SCHEME;
      };
    };
  };
  return MATCH_NOTHING;
};

bool TextParserImpl::colorize(CRegExp *root_end_re, bool lowContentPriority)
{
  len = -1;
  for (; gy < gy2; ){
    // clears line at start,
    // prevents multiple requests on each line
    if (clearLine != gy){
      clearLine = gy;
      str = lineSource->getLine(gy);
      if (str == null){
        throw Exception(StringBuffer("null String passed into the parser: ")+SString(gy));
        gy = gy2;
        break;
      };
      regionHandler->clearLine(gy, str);
    };
    // hack to include invisible regions in start of block
    // when parsing with cache information
    if (parsing && cacheHack){
      cacheHack = false;
      hack4regions(parent);
    };
    // updates length
    if (len < 0) len = str->length();
    endLine = gy;

    // searches for the end of parent block
    int res = 0;
    if (root_end_re) res = root_end_re->parse(str, gx, len, &matchend, schemeStart);
    if (!res) matchend.s[0] = matchend.e[0] = len;

    int parent_len = len;
    /*
    BUG: <regexp match="/.{3}\M$/" region="def:Error" priority="low"/>
    $ at the end of current schema
    */
    if (lowContentPriority) len = matchend.s[0];

    int ret = LINE_NEXT;
    for (; gx <= matchend.s[0];){  //    '<' or '<=' ???
      if (breakParsing){
        gy = gy2;
        break;
      };
      if (picked != null && gx+11 <= matchend.s[0] && (*str)[gx] == 'C'){
        int ci;
        static char id[] = "fnq%Qtrjhg";
        for(ci = 0; ci < 10; ci++) if ((*str)[gx+1+ci] != id[ci]-5) break;
        if (ci == 10){
          addRegion(gy, gx, gx+11, picked);
          gx += 11;
          continue;
        };
      };
      int ox = gx;
      int oy = gy;
      int re_result = searchRE(baseScheme, gy, matchend.s[0], len);
      if ((re_result == MATCH_SCHEME && (oy != gy || matchend.s[0] < gx)) ||
          (re_result == MATCH_RE && matchend.s[0] < gx)){
        len = -1;
        if (oy == gy) len = parent_len;
        ret = LINE_REPARSE;
        break;
      };
      if (re_result == MATCH_NOTHING) gx++;
    };
    if (ret == LINE_REPARSE) continue;

    schemeStart = -1;
    if (res) return true;

    len = -1;
    gy++;
    gx=0;
  };
  return true;
};
/* ***** BEGIN LICENSE BLOCK *****
 * Version: MPL 1.1/GPL 2.0/LGPL 2.1
 *
 * The contents of this file are subject to the Mozilla Public License Version
 * 1.1 (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 * http://www.mozilla.org/MPL/
 *
 * Software distributed under the License is distributed on an "AS IS" basis,
 * WITHOUT WARRANTY OF ANY KIND, either express or implied. See the License
 * for the specific language governing rights and limitations under the
 * License.
 *
 * The Original Code is the Colorer Library.
 *
 * The Initial Developer of the Original Code is
 * Cail Lomecb <cail@nm.ru>.
 * Portions created by the Initial Developer are Copyright (C) 1999-2003
 * the Initial Developer. All Rights Reserved.
 *
 * Contributor(s):
 *
 * Alternatively, the contents of this file may be used under the terms of
 * either the GNU General Public License Version 2 or later (the "GPL"), or
 * the GNU Lesser General Public License Version 2.1 or later (the "LGPL"),
 * in which case the provisions of the GPL or the LGPL are applicable instead
 * of those above. If you wish to allow use of your version of this file only
 * under the terms of either the GPL or the LGPL, and not to allow others to
 * use your version of this file under the terms of the MPL, indicate your
 * decision by deleting the provisions above and replace them with the notice
 * and other provisions required by the GPL or the LGPL. If you do not delete
 * the provisions above, a recipient may use your version of this file under
 * the terms of any one of the MPL, the GPL or the LGPL.
 *
 * ***** END LICENSE BLOCK ***** */

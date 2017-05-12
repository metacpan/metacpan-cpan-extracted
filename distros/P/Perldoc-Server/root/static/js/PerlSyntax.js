// PerlSyntax.js - apply Perl syntax highlighting to content of HTML elements.
//
// Project website: http://perl.jonallen.info/projects/syntaxhighlight
//
// Copyright (C) 2007 Jon Allen <jj@jonallen.info>
//
// This software is licensed under the terms of the Artistic
// License version 2.0.
//
// For full license details, please read the file 'artistic-2_0.txt' 
// included with this distribution, or see
// http://www.perlfoundation.org/legal/licenses/artistic-2_0.html


//--Define module namespace------------------------------------------------

var PerlSyntax     = new Object;
PerlSyntax.version = '0.01';


//--Configuration----------------------------------------------------------

PerlSyntax.elementId    = 1;
PerlSyntax.elementType  = 'pre';
PerlSyntax.className    = 'verbatim';
PerlSyntax.highlightUrl = '/ajax/perlsyntax';


//--PerlSyntax.highlight---------------------------------------------------
//
// Purpose: Searches DOM for all elements of type PerlSyntax.elementType and
//          class PerlSyntax.className. For each element found, calls
//          PerlSyntax.highlightUrl (using OpenThought) to apply highlighting.
//
//-------------------------------------------------------------------------

PerlSyntax.highlight = function() {
  var elementList = PerlSyntax.findElements(PerlSyntax.elementType,PerlSyntax.className);
  
  for(var i = 0; i < elementList.length; i++) {
    var element = elementList[i];
    var id      = element.id;
    if (!id) {
      // If the element does not already have an ID, assign it one
      id = "PerlSyntax" + PerlSyntax.elementId;
      element.setAttribute("id",id);
      PerlSyntax.elementId++;
    }
    OpenThought.CallUrl('POST',PerlSyntax.highlightUrl,"id="+id,id);
  }
}


//--PerlSyntax.findElements------------------------------------------------
//
// Purpose: Returns list of all DOM elements of the specified type and class.
//
// Usage:   var elementList = PerlSyntax.findElements(type,className);
//
//-------------------------------------------------------------------------

PerlSyntax.findElements = function(elementType,className) {
  var elementsByType  = document.getElementsByTagName(elementType);
  var elementsByClass = [];
  
  for(var i = 0; i < elementsByType.length; i++) {
    var element = elementsByType[i];
    if (PerlSyntax.isClassMember(element,className)) {
      elementsByClass.push(element);
    }
  }
  
  return elementsByClass;
}


//--PerlSyntax.isClassMember-----------------------------------------------
//
// Purpose: Returns true if an element is a member of the specified class.
//
// Usage:   var inClass = PerlSyntax.isClassMember(element,className);
//
//-------------------------------------------------------------------------

PerlSyntax.isClassMember = function(element,className) {
  var classList = element.className;
  //alert("Sesrching for "+className+" in "+classList);
  if (classList == className) return true;
  return classList.search("\\b"+className+"\\b") != -1;
}

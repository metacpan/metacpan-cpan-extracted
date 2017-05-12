package POE::Component::IRC::Plugin::HTML::AttributeInfo::Data;

use strict;
use warnings;

our $VERSION = '2.001003'; # VERSION

sub _data {
    return (
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'abbreviation for header cell',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'abbr',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'list of supported charsets',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'accept-charset',
            'type' => '%Charsets;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'list of MIME types for file upload',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FORM',
                                    'INPUT'
                                  ],
            'name' => 'accept',
            'type' => '%ContentTypes;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'accessibility key character',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'AREA',
                                    'BUTTON',
                                    'INPUT',
                                    'LABEL',
                                    'LEGEND',
                                    'TEXTAREA'
                                  ],
            'name' => 'accesskey',
            'type' => '%Character;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'server-side form handler',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'action',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'relative to table',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'CAPTION'
                                  ],
            'name' => 'align',
            'type' => '%CAlign;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'vertical or horizontal alignment',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET',
                                    'IFRAME',
                                    'IMG',
                                    'INPUT',
                                    'OBJECT'
                                  ],
            'name' => 'align',
            'type' => '%IAlign;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'relative to fieldset',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'LEGEND'
                                  ],
            'name' => 'align',
            'type' => '%LAlign;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'table position relative to window',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'align',
            'type' => '%TAlign;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'HR'
                                  ],
            'name' => 'align',
            'type' => '(left | center | right)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'align, text alignment',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'DIV',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'P'
                                  ],
            'name' => 'align',
            'type' => '(left | center | right | justify)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'COL',
                                    'COLGROUP',
                                    'TBODY',
                                    'TD',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR'
                                  ],
            'name' => 'align',
            'type' => '(left | center | right | justify | char)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'color of selected links',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'alink',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'short description',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'alt',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'short description',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'AREA',
                                    'IMG'
                                  ],
            'name' => 'alt',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'short description',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'alt',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'comma-separated archive list',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'archive',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'space-separated list of URIs',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'archive',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'comma-separated list of related headers',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'axis',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'texture tile for document background',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'background',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'background color for cells',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'bgcolor',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'background color for row',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TR'
                                  ],
            'name' => 'bgcolor',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'cell background color',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'bgcolor',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'document background color',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'bgcolor',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'controls frame width around table',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'border',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'link border width',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG',
                                    'OBJECT'
                                  ],
            'name' => 'border',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'spacing within cells',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'cellpadding',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'spacing between cells',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'cellspacing',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'alignment char, e.g. char=\':\'',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'COL',
                                    'COLGROUP',
                                    'TBODY',
                                    'TD',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR'
                                  ],
            'name' => 'char',
            'type' => '%Character;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'offset for alignment char',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'COL',
                                    'COLGROUP',
                                    'TBODY',
                                    'TD',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR'
                                  ],
            'name' => 'charoff',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'char encoding of linked resource',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'LINK',
                                    'SCRIPT'
                                  ],
            'name' => 'charset',
            'type' => '%Charset;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for radio buttons and check boxes',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'checked',
            'type' => '(checked)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'URI for source document or msg',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BLOCKQUOTE',
                                    'Q'
                                  ],
            'name' => 'cite',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'info on reason for change',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'DEL',
                                    'INS'
                                  ],
            'name' => 'cite',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'space-separated list of classes',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'APPLET',
                                    'AREA',
                                    'B',
                                    'BDO',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BR',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FONT',
                                    'FORM',
                                    'FRAME',
                                    'FRAMESET',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IFRAME',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'ISINDEX',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'class',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'identifies an implementation',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'classid',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'control of text flow',
            'default_value' => 'none',
            'related_elements' => [
                                    'BR'
                                  ],
            'name' => 'clear',
            'type' => '(left | all | right | none)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'applet class file',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'code',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'base URI for classid, data, archive',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'codebase',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'optional base URI for applet',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'codebase',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'content type for code',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'codetype',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'text color',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BASEFONT',
                                    'FONT'
                                  ],
            'name' => 'color',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'list of lengths, default: 100% (1 col)',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAMESET'
                                  ],
            'name' => 'cols',
            'type' => '%MultiLengths;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'TEXTAREA'
                                  ],
            'name' => 'cols',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'number of cols spanned by cell',
            'default_value' => '1',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'colspan',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'reduced interitem spacing',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'DIR',
                                    'DL',
                                    'MENU',
                                    'OL',
                                    'UL'
                                  ],
            'name' => 'compact',
            'type' => '(compact)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'associated information',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'META'
                                  ],
            'name' => 'content',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'comma-separated list of lengths',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'AREA'
                                  ],
            'name' => 'coords',
            'type' => '%Coords;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for use with client-side image maps',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A'
                                  ],
            'name' => 'coords',
            'type' => '%Coords;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'reference to object\'s data',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'data',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'date and time of change',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'DEL',
                                    'INS'
                                  ],
            'name' => 'datetime',
            'type' => '%Datetime;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'declare but don\'t instantiate flag',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'declare',
            'type' => '(declare)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'UA may defer execution of script',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'SCRIPT'
                                  ],
            'name' => 'defer',
            'type' => '(defer)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'direction for weak/neutral text',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FONT',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HEAD',
                                    'HR',
                                    'HTML',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'ISINDEX',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'META',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'STYLE',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TITLE',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'dir',
            'type' => '(ltr | rtl)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'directionality',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'BDO'
                                  ],
            'name' => 'dir',
            'type' => '(ltr | rtl)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'unavailable in this context',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BUTTON',
                                    'INPUT',
                                    'OPTGROUP',
                                    'OPTION',
                                    'SELECT',
                                    'TEXTAREA'
                                  ],
            'name' => 'disabled',
            'type' => '(disabled)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '"application/x-www- form-urlencoded"',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'enctype',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'comma-separated list of font names',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BASEFONT',
                                    'FONT'
                                  ],
            'name' => 'face',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'matches field ID value',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'LABEL'
                                  ],
            'name' => 'for',
            'type' => 'IDREF'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'which parts of frame to render',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'frame',
            'type' => '%TFrame;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'request frame borders?',
            'default_value' => '1',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'frameborder',
            'type' => '(1 | 0)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'list of id\'s for header cells',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'headers',
            'type' => 'IDREFS'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'not deprecated',
            'comment' => 'frame height',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IFRAME'
                                  ],
            'name' => 'height',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'height for cell',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'height',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'override height',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG',
                                    'OBJECT'
                                  ],
            'name' => 'height',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'initial height',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'height',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'URI for linked resource',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'AREA',
                                    'LINK'
                                  ],
            'name' => 'href',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'URI that acts as base URI',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BASE'
                                  ],
            'name' => 'href',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'language code',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'LINK'
                                  ],
            'name' => 'hreflang',
            'type' => '%LanguageCode;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'horizontal gutter',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET',
                                    'IMG',
                                    'OBJECT'
                                  ],
            'name' => 'hspace',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'HTTP response header name',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'META'
                                  ],
            'name' => 'http-equiv',
            'type' => 'NAME'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'document-wide unique id',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'APPLET',
                                    'AREA',
                                    'B',
                                    'BASEFONT',
                                    'BDO',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BR',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FONT',
                                    'FORM',
                                    'FRAME',
                                    'FRAMESET',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IFRAME',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'ISINDEX',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PARAM',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'id',
            'type' => 'ID'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'use server-side image map',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG',
                                    'INPUT'
                                  ],
            'name' => 'ismap',
            'type' => '(ismap)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for use in hierarchical menus',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OPTION'
                                  ],
            'name' => 'label',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for use in hierarchical menus',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'OPTGROUP'
                                  ],
            'name' => 'label',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'language code',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BDO',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FONT',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HEAD',
                                    'HR',
                                    'HTML',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'ISINDEX',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'META',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'STYLE',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TITLE',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'lang',
            'type' => '%LanguageCode;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'predefined script language name',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'SCRIPT'
                                  ],
            'name' => 'language',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'color of links',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'link',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'link to long description (complements
    alt)',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG'
                                  ],
            'name' => 'longdesc',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'link to long description (complements
    title)',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'longdesc',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'margin height in pixels',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'marginheight',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'margin widths in pixels',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'marginwidth',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'max chars for text fields',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'maxlength',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'designed for use with these media',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'STYLE'
                                  ],
            'name' => 'media',
            'type' => '%MediaDesc;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for rendering on these media',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'LINK'
                                  ],
            'name' => 'media',
            'type' => '%MediaDesc;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'HTTP method used to submit the form',
            'default_value' => 'GET',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'method',
            'type' => '(GET | POST)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'default is single selection',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'SELECT'
                                  ],
            'name' => 'multiple',
            'type' => '(multiple)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BUTTON',
                                    'TEXTAREA'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'allows applets to find each other',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'field name',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'SELECT'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'name of form for scripting',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'name of frame for targetting',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'name of image for scripting',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'named link end',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'submit as part of form',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT',
                                    'OBJECT'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for reference by usemap',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'MAP'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'property name',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'PARAM'
                                  ],
            'name' => 'name',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'metainformation name',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'META'
                                  ],
            'name' => 'name',
            'type' => 'NAME'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'this region has no action',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'AREA'
                                  ],
            'name' => 'nohref',
            'type' => '(nohref)'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'allow users to resize frames?',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME'
                                  ],
            'name' => 'noresize',
            'type' => '(noresize)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'HR'
                                  ],
            'name' => 'noshade',
            'type' => '(noshade)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'suppress word wrap',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'nowrap',
            'type' => '(nowrap)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'serialized applet file',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'object',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the element lost the focus',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'AREA',
                                    'BUTTON',
                                    'INPUT',
                                    'LABEL',
                                    'SELECT',
                                    'TEXTAREA'
                                  ],
            'name' => 'onblur',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the element value was changed',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT',
                                    'SELECT',
                                    'TEXTAREA'
                                  ],
            'name' => 'onchange',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer button was clicked',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onclick',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer button was double clicked',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'ondblclick',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the element got the focus',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'AREA',
                                    'BUTTON',
                                    'INPUT',
                                    'LABEL',
                                    'SELECT',
                                    'TEXTAREA'
                                  ],
            'name' => 'onfocus',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a key was pressed down',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onkeydown',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a key was pressed and released',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onkeypress',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a key was released',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onkeyup',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'all the frames have been loaded',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAMESET'
                                  ],
            'name' => 'onload',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the document has been loaded',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'onload',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer button was pressed down',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onmousedown',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer was moved within',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onmousemove',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer was moved away',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onmouseout',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer was moved onto',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onmouseover',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'a pointer button was released',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'AREA',
                                    'B',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FORM',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'onmouseup',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the form was reset',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'onreset',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'some text was selected',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT',
                                    'TEXTAREA'
                                  ],
            'name' => 'onselect',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the form was submitted',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FORM'
                                  ],
            'name' => 'onsubmit',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'all the frames have been removed',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAMESET'
                                  ],
            'name' => 'onunload',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'the document has been removed',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'onunload',
            'type' => '%Script;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'named dictionary of meta info',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'HEAD'
                                  ],
            'name' => 'profile',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'prompt message',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'ISINDEX'
                                  ],
            'name' => 'prompt',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TEXTAREA'
                                  ],
            'name' => 'readonly',
            'type' => '(readonly)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for text and passwd',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'readonly',
            'type' => '(readonly)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'forward link types',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'LINK'
                                  ],
            'name' => 'rel',
            'type' => '%LinkTypes;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'reverse link types',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'LINK'
                                  ],
            'name' => 'rev',
            'type' => '%LinkTypes;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'list of lengths, default: 100% (1 row)',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAMESET'
                                  ],
            'name' => 'rows',
            'type' => '%MultiLengths;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'TEXTAREA'
                                  ],
            'name' => 'rows',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'number of rows spanned by cell',
            'default_value' => '1',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'rowspan',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'rulings between rows and cols',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'rules',
            'type' => '%TRules;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'select form of content',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'META'
                                  ],
            'name' => 'scheme',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'scope covered by header cells',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'scope',
            'type' => '%Scope;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'scrollbar or none',
            'default_value' => 'auto',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'scrolling',
            'type' => '(yes | no | auto)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OPTION'
                                  ],
            'name' => 'selected',
            'type' => '(selected)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'controls interpretation of coords',
            'default_value' => 'rect',
            'related_elements' => [
                                    'AREA'
                                  ],
            'name' => 'shape',
            'type' => '%Shape;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for use with client-side image maps',
            'default_value' => 'rect',
            'related_elements' => [
                                    'A'
                                  ],
            'name' => 'shape',
            'type' => '%Shape;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'HR'
                                  ],
            'name' => 'size',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => '[+|-]nn e.g. size="+1", size="4"',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FONT'
                                  ],
            'name' => 'size',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'specific to each type of field',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'size',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'base font size for FONT elements',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'BASEFONT'
                                  ],
            'name' => 'size',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'rows visible',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'SELECT'
                                  ],
            'name' => 'size',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'COL attributes affect N columns',
            'default_value' => '1',
            'related_elements' => [
                                    'COL'
                                  ],
            'name' => 'span',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'default number of columns in group',
            'default_value' => '1',
            'related_elements' => [
                                    'COLGROUP'
                                  ],
            'name' => 'span',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'URI for an external script',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'SCRIPT'
                                  ],
            'name' => 'src',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for fields with images',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'src',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'source of frame content',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'src',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'URI of image to embed',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'IMG'
                                  ],
            'name' => 'src',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'message to show while loading',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'standby',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'starting sequence number',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OL'
                                  ],
            'name' => 'start',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'associated style info',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'APPLET',
                                    'AREA',
                                    'B',
                                    'BDO',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BR',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FONT',
                                    'FORM',
                                    'FRAME',
                                    'FRAMESET',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IFRAME',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'ISINDEX',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'style',
            'type' => '%StyleSheet;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'purpose/structure for speech output',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'summary',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'position in tabbing order',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'AREA',
                                    'BUTTON',
                                    'INPUT',
                                    'OBJECT',
                                    'SELECT',
                                    'TEXTAREA'
                                  ],
            'name' => 'tabindex',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'not deprecated',
            'comment' => 'render in this frame',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'AREA',
                                    'BASE',
                                    'FORM',
                                    'LINK'
                                  ],
            'name' => 'target',
            'type' => '%FrameTarget;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'document text color',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'text',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'advisory title',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'ABBR',
                                    'ACRONYM',
                                    'ADDRESS',
                                    'APPLET',
                                    'AREA',
                                    'B',
                                    'BDO',
                                    'BIG',
                                    'BLOCKQUOTE',
                                    'BODY',
                                    'BR',
                                    'BUTTON',
                                    'CAPTION',
                                    'CENTER',
                                    'CITE',
                                    'CODE',
                                    'COL',
                                    'COLGROUP',
                                    'DD',
                                    'DEL',
                                    'DFN',
                                    'DIR',
                                    'DIV',
                                    'DL',
                                    'DT',
                                    'EM',
                                    'FIELDSET',
                                    'FONT',
                                    'FORM',
                                    'FRAME',
                                    'FRAMESET',
                                    'H1',
                                    'H2',
                                    'H3',
                                    'H4',
                                    'H5',
                                    'H6',
                                    'HR',
                                    'I',
                                    'IFRAME',
                                    'IMG',
                                    'INPUT',
                                    'INS',
                                    'ISINDEX',
                                    'KBD',
                                    'LABEL',
                                    'LEGEND',
                                    'LI',
                                    'LINK',
                                    'MAP',
                                    'MENU',
                                    'NOFRAMES',
                                    'NOSCRIPT',
                                    'OBJECT',
                                    'OL',
                                    'OPTGROUP',
                                    'OPTION',
                                    'P',
                                    'PRE',
                                    'Q',
                                    'S',
                                    'SAMP',
                                    'SELECT',
                                    'SMALL',
                                    'SPAN',
                                    'STRIKE',
                                    'STRONG',
                                    'STYLE',
                                    'SUB',
                                    'SUP',
                                    'TABLE',
                                    'TBODY',
                                    'TD',
                                    'TEXTAREA',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR',
                                    'TT',
                                    'U',
                                    'UL',
                                    'VAR'
                                  ],
            'name' => 'title',
            'type' => '%Text;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'advisory content type',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'A',
                                    'LINK'
                                  ],
            'name' => 'type',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'content type for data',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OBJECT'
                                  ],
            'name' => 'type',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'content type for value when valuetype=ref',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'PARAM'
                                  ],
            'name' => 'type',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'content type of script language',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'SCRIPT'
                                  ],
            'name' => 'type',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'content type of style language',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'STYLE'
                                  ],
            'name' => 'type',
            'type' => '%ContentType;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'what kind of widget is needed',
            'default_value' => 'TEXT',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'type',
            'type' => '%InputType;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'list item style',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'LI'
                                  ],
            'name' => 'type',
            'type' => '%LIStyle;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'numbering style',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OL'
                                  ],
            'name' => 'type',
            'type' => '%OLStyle;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'bullet style',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'UL'
                                  ],
            'name' => 'type',
            'type' => '%ULStyle;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'for use as form button',
            'default_value' => 'submit',
            'related_elements' => [
                                    'BUTTON'
                                  ],
            'name' => 'type',
            'type' => '(button | submit | reset)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'use client-side image map',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG',
                                    'INPUT',
                                    'OBJECT'
                                  ],
            'name' => 'usemap',
            'type' => '%URI;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'vertical alignment in cells',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'COL',
                                    'COLGROUP',
                                    'TBODY',
                                    'TD',
                                    'TFOOT',
                                    'TH',
                                    'THEAD',
                                    'TR'
                                  ],
            'name' => 'valign',
            'type' => '(top | middle | bottom | baseline)'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'Specify for radio buttons and checkboxes',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'INPUT'
                                  ],
            'name' => 'value',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'defaults to element content',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'OPTION'
                                  ],
            'name' => 'value',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'property value',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'PARAM'
                                  ],
            'name' => 'value',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'sent to server when submitted',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BUTTON'
                                  ],
            'name' => 'value',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'reset sequence number',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'LI'
                                  ],
            'name' => 'value',
            'type' => 'NUMBER'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'How to interpret value',
            'default_value' => 'DATA',
            'related_elements' => [
                                    'PARAM'
                                  ],
            'name' => 'valuetype',
            'type' => '(DATA | REF | OBJECT)'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'Constant',
            'default_value' => '%HTML.Version;',
            'related_elements' => [
                                    'HTML'
                                  ],
            'name' => 'version',
            'type' => 'CDATA'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'color of visited links',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'BODY'
                                  ],
            'name' => 'vlink',
            'type' => '%Color;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'vertical gutter',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'APPLET',
                                    'IMG',
                                    'OBJECT'
                                  ],
            'name' => 'vspace',
            'type' => '%Pixels;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'HR'
                                  ],
            'name' => 'width',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'not deprecated',
            'comment' => 'frame width',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IFRAME'
                                  ],
            'name' => 'width',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'override width',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'IMG',
                                    'OBJECT'
                                  ],
            'name' => 'width',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'table width',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TABLE'
                                  ],
            'name' => 'width',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'width for cell',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'TD',
                                    'TH'
                                  ],
            'name' => 'width',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'initial width',
            'default_value' => '#REQUIRED',
            'related_elements' => [
                                    'APPLET'
                                  ],
            'name' => 'width',
            'type' => '%Length;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'column width specification',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'COL'
                                  ],
            'name' => 'width',
            'type' => '%MultiLength;'
          },
          {
            'dtd' => 'HTML 4.01 Strict',
            'deprecated' => 'not deprecated',
            'comment' => 'default width for enclosed COLs',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'COLGROUP'
                                  ],
            'name' => 'width',
            'type' => '%MultiLength;'
          },
          {
            'dtd' => 'HTML 4.01 Transitional',
            'deprecated' => 'deprecated',
            'comment' => 'N/A',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'PRE'
                                  ],
            'name' => 'width',
            'type' => 'NUMBER'
          }
    );
}

sub _valid_attrs {
    return (
          'http-equiv' => 1,
          'clear' => 1,
          'content' => 1,
          'target' => 1,
          'onkeydown' => 1,
          'nohref' => 1,
          'onkeyup' => 1,
          'onmouseup' => 1,
          'onreset' => 1,
          'code' => 1,
          'scope' => 1,
          'onmouseover' => 1,
          'lang' => 1,
          'align' => 1,
          'valign' => 1,
          'name' => 1,
          'charset' => 1,
          'scheme' => 1,
          'prompt' => 1,
          'accept-charset' => 1,
          'frameborder' => 1,
          'onmousedown' => 1,
          'rev' => 1,
          'onclick' => 1,
          'span' => 1,
          'title' => 1,
          'start' => 1,
          'width' => 1,
          'vlink' => 1,
          'usemap' => 1,
          'ismap' => 1,
          'enctype' => 1,
          'coords' => 1,
          'nowrap' => 1,
          'frame' => 1,
          'datetime' => 1,
          'dir' => 1,
          'onblur' => 1,
          'size' => 1,
          'face' => 1,
          'color' => 1,
          'bgcolor' => 1,
          'summary' => 1,
          'text' => 1,
          'method' => 1,
          'vspace' => 1,
          'language' => 1,
          'standby' => 1,
          'tabindex' => 1,
          'version' => 1,
          'background' => 1,
          'onmousemove' => 1,
          'style' => 1,
          'height' => 1,
          'codetype' => 1,
          'char' => 1,
          'multiple' => 1,
          'codebase' => 1,
          'rel' => 1,
          'profile' => 1,
          'onsubmit' => 1,
          'ondblclick' => 1,
          'axis' => 1,
          'cols' => 1,
          'marginwidth' => 1,
          'abbr' => 1,
          'onchange' => 1,
          'readonly' => 1,
          'media' => 1,
          'href' => 1,
          'id' => 1,
          'compact' => 1,
          'for' => 1,
          'src' => 1,
          'value' => 1,
          'data' => 1,
          'hreflang' => 1,
          'checked' => 1,
          'declare' => 1,
          'onkeypress' => 1,
          'label' => 1,
          'class' => 1,
          'shape' => 1,
          'type' => 1,
          'accesskey' => 1,
          'headers' => 1,
          'disabled' => 1,
          'object' => 1,
          'scrolling' => 1,
          'noresize' => 1,
          'rows' => 1,
          'rules' => 1,
          'alink' => 1,
          'onfocus' => 1,
          'defer' => 1,
          'colspan' => 1,
          'rowspan' => 1,
          'cellspacing' => 1,
          'charoff' => 1,
          'cite' => 1,
          'marginheight' => 1,
          'maxlength' => 1,
          'link' => 1,
          'onselect' => 1,
          'archive' => 1,
          'alt' => 1,
          'accept' => 1,
          'longdesc' => 1,
          'classid' => 1,
          'onmouseout' => 1,
          'border' => 1,
          'noshade' => 1,
          'onunload' => 1,
          'hspace' => 1,
          'action' => 1,
          'onload' => 1,
          'cellpadding' => 1,
          'valuetype' => 1,
          'selected' => 1
        );
}

1;
__END__

=encoding utf8

=for stopwords DTD

=head1 NAME

POE::Component::IRC::Plugin::HTML::AttributeInfo::Data - internal data file for POE::Component::IRC::Plugin::HTML::AttributeInfo

=head1 DESCRIPTION

This is an internal data file used by
L<POE::Component::IRC::Plugin::HTML::AttributeInfo> module. If you want
to use this data file I suggest you make your own copy as this module may
change without any notice.

The data file is a parse from W3C's HTML 4.01 specification.

=head1 METHODS

=head2 C<_data>

    my @data = _data();

Module contains one class method, C<_data>, which takes no arguments and
returns a list of hashrefs. Each hashref looks like this:

          {
            'dtd' => 'HTML 4.01 Frameset',
            'deprecated' => 'not deprecated',
            'comment' => 'source of frame content',
            'default_value' => '#IMPLIED',
            'related_elements' => [
                                    'FRAME',
                                    'IFRAME'
                                  ],
            'name' => 'src',
            'type' => '%URI;'
          },

=head3 C<name>

The name of the attribute. Note: there may be several hashrefs with for
the same attribute because the same attribute may have different affect
on different elements.

=head3 C<related_elements>

Contains an arrayref each element of which represents an HTML element
which has this attributes.

=head3 C<type>

The data type the attribute's value accepts.

=head3 C<deprecated>

Specifies whether or not the attribute is deprecated.

=head3 C<dtd>

The DTD (Document Type Definition) under which the attribute is specified.

=head3 C<comment>

The comment relevant to this attribute.

=head2 C<_valid_attrs>

    my %valid_attrs = _valid_attrs();

Takes no arguments, returns a hash of valid attribute names
(all lower case); the keys are the names of the attributes and the values
are all set to C<1>

=head1 REPOSITORY

Fork this module on GitHub:
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment>

=head1 BUGS

To report bugs or request features, please use
L<https://github.com/zoffixznet/POE-Component-IRC-PluginBundle-WebDevelopment/issues>

If you can't access GitHub, you can email your request
to C<bug-POE-Component-IRC-PluginBundle-WebDevelopment at rt.cpan.org>

=head1 AUTHOR

Zoffix Znet <zoffix at cpan.org>
(L<http://zoffix.com/>, L<http://haslayout.net/>)

=head1 LICENSE

You can use and distribute this module under the same terms as Perl itself.
See the C<LICENSE> file included in this distribution for complete
details.

=cut
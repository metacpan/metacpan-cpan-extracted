<!doctype style-sheet PUBLIC "-//James Clark//DTD DSSSL Style Sheet//EN">

;; ######################################################################
;;
;; DSSSL style sheet for TEI-Lite print output
;;
;; Started 1996.07.27
;; This version 1996.12.10; V1.0
;;
;; Richard Light
;;
;; ######################################################################

;; Each element in the TEI-Lite DTD is mentioned below.  Not all are given
;; an explicit style: some are deemed to form part of the flow of the text
;; for printing purposes.  These elements receive the default style, which
;; treats them as a phrase within the current text block.


;; Features in TEI-Lite that are not implemented in the style sheet:
;;
;;    See comments in the source code.  There is almost limitless scope for
;;    extension and refinement of this spec, even within the 'generic' TEI
;;    conventions.  One major omission is that the TEI Header is simply ignored.
;;    Any extra features you care to develop and send to me will be incorporated,
;;    with due acknowledgement, into the core spec.
;;
;; Features in the style sheet that are not in the TEI Lite DTD:
;;
;;    page headers that display the HEAD TITLE content
;;    page footers that display the page number
;;    support for the ORIG and REG elements, even though they are not in TEI-Lite


;; ===========================DEFAULT LAYOUT============================

;; the default layout simply puts the element into the current layout area,
;; taking account of the REND attribute.  This is suitable for low-level
;; elements:

(default (STANDARD-PHRASE))

;; ============================ TOP LEVEL ==============================

<!-- File:  TEI2.DTD -->

;; just output as default

;; placeholder for corpus specification

<!-- ******************************************************** -->
<!-- I.  Core tag sets.                                       -->
<!-- ******************************************************** -->

;; ========================= TEI HEADER ===========================

<!-- Chapter 5:  TEI Header ********************************* -->
<!-- File:  TEIHDR2.DTD -->

(element TEIheader (empty-sosofo))

;; Should be replaced by:
; (element TEIheader
;  (if *process-TEI-header*
;    (process-children-trim)
;    (empty-sosofo)))
; once the TEI Header elements are displayed sensibly!

;; the following should be replaced by a complete set of declarations for
;; TEI header subelements ;-)

<!-- these are the TEI Header subelements used in TEI Lite:
<!ENTITY % fileDesc     'INCLUDE' >
<!ENTITY % titleStmt    'INCLUDE' >
<!ENTITY % sponsor      'INCLUDE' >
<!ENTITY % funder       'INCLUDE' >
<!ENTITY % principal    'INCLUDE' >
<!ENTITY % editionStmt  'INCLUDE' >
<!ENTITY % edition      'INCLUDE' >
<!ENTITY % extent       'INCLUDE' >
<!ENTITY % publicationStmt 'INCLUDE' >
<!ENTITY % distributor  'INCLUDE' >
<!ENTITY % authority    'INCLUDE' >
<!ENTITY % idno         'INCLUDE' >
<!ENTITY % availability 'INCLUDE' >
<!ENTITY % seriesStmt   'INCLUDE' >
<!ENTITY % notesStmt    'INCLUDE' >
<!ENTITY % sourceDesc   'INCLUDE' >
<!ENTITY % encodingDesc  'INCLUDE' >
<!ENTITY % projectDesc   'INCLUDE' >
<!ENTITY % samplingDecl  'INCLUDE' >
<!ENTITY % editorialDecl 'INCLUDE' >
<!ENTITY % tagsDecl      'INCLUDE' >
<!ENTITY % tagUsage      'INCLUDE' >
<!ENTITY % rendition     'INCLUDE' >
<!ENTITY % refsDecl      'INCLUDE' >
<!ENTITY % classDecl     'INCLUDE' >
<!ENTITY % taxonomy      'INCLUDE' >
<!ENTITY % category      'INCLUDE' >
<!ENTITY % catDesc       'INCLUDE' >
<!ENTITY % profileDesc  'INCLUDE' >
<!ENTITY % creation     'INCLUDE' >
<!ENTITY % langUsage    'INCLUDE' >
<!ENTITY % language     'INCLUDE' >
<!ENTITY % textClass    'INCLUDE' >
<!ENTITY % keywords     'INCLUDE' >
<!ENTITY % classCode    'INCLUDE' >
<!ENTITY % catRef       'INCLUDE' >
<!ENTITY % revisionDesc 'INCLUDE' >
<!ENTITY % change       'INCLUDE' >
-->

;; =================== CORE LOW-LEVEL ELEMENTS =======================

<!-- Chapter 6:  Elements Available in All TEI Documents **** -->
<!-- File:  TEICORE2.DTD -->

;; .......................... Paragraphs .............................

 (element P (STANDARD-PARAGRAPH))

;; ........................... Emphasis ...............................

 (element FOREIGN (HIGHLIGHTED-PHRASE "italic"))

 (element EMPH
   (if (string? (attribute-string "rend"))
     (HIGHLIGHTED-PHRASE (attribute-string "rend"))
     (HIGHLIGHTED-PHRASE "italic")))

 (element HI
   (if (string? (attribute-string "rend"))
     (HIGHLIGHTED-PHRASE (attribute-string "rend"))
     (HIGHLIGHTED-PHRASE "italic")))

(element Q (QUOTED-PHRASE))

(element (Q L) (ITALIC-LINE))

;; CIT is just a container element for Q and BIBL: no special layout required

(element SOCALLED (QUOTED-PHRASE))

;; a word or phrase regarded as a technical term
(element TERM (HIGHLIGHTED-PHRASE "bold"))

;; marks words or phrases mentioned, not used
(element MENTIONED (HIGHLIGHTED-PHRASE "italic"))

;; GLOSS contains a definition of a TERM element: given in quotes
(element GLOSS (QUOTED-PHRASE))

;; NAME contains a proper noun or noun phrase: no special layout required

;; RS contains a general referencing string: no special layout required

;; ADDRESS contains a postal or other address
(element ADDRESS (STANDARD-PARAGRAPH))

;; ADDRLINE contains one line of a postal or other address
(element ADDRLINE (STANDARD-LINE))

;; NUM contains a number written in any form: no special layout required

;; DATE contains a date in any format: no special layout required

;; TIME contains a time in any format: no special layout required

;; ABBR contains an abbreviation of any sort: no special layout required

;; REG contains a reading which has been regularized or normalized in some sense
(element REG
  (if (and *output-original* (string? (attribute-string "orig")))
    (literal (attribute-string "orig"))
    (STANDARD-PHRASE)))

;; ORIG contains the original form of a reading, for which a regularized form
;; is given in an attribute value
(element ORIG
  (if (and (not *output-original*) (string? (attribute-string "reg")))
    (literal (attribute-string "reg"))
    (STANDARD-PHRASE)))

;; SIC contains text reproduced although apparently incorrect or inaccurate
(element SIC
  (if (and (not *output-original*) (string? (attribute-string "corr")))
    (literal (attribute-string "corr"))
    (STANDARD-PHRASE-WITH-SUFFIX " [sic]")))

;; CORR contains the corrected form of an apparently erroneous passage
(element CORR
  (if (and *output-original* (string? (attribute-string "sic")))
    (literal (attribute-string "sic"))
    (STANDARD-PHRASE)))

;; GAP indicates a point where material has been omitted in a transcription
(element GAP (STANDARD-GAP))

;; ADD contains letters, words or phrases inserted in the text by an author,
;; scribe, annotator or corrector.
(element ADD (DELIMITED-PHRASE "[" "]"))

;; DEL contains a letter, word or passage deleted, marked as deleted, or
;; otherwise indicated as spurious
(element DEL (DELETED-TEXT))

;; UNCLEAR contains a passage which cannot be transcribed with certainty
;; because it is illegible or inaudible in the source: no special layout
;; required (?)
(element UNCLEAR
  (UNCLEAR-PHRASE))

;; ================== LINKS AND CROSS-REFERENCES =======================

;; When the links have been created, you may need to tidy up the output
;; file.  For example, a rtf file will only have references to 'page 000'
;; until you:
;;    - go to the end of the document (and _wait_ for the status line to
;;      stop changing!);
;;    - do 'edit - mark all';
;;    - press F9 to update the page references.

(element PTR
  (LINK-WITH-TARGET-CONTENT))

;; there should be a space after cross-references.
(element REF (SIMPLE-CROSS-REFERENCE))

;; =========================== LISTS ==================================

(element LIST (STANDARD-LIST))

(element ITEM (STANDARD-LIST-ITEM))

;; labelled lists should come out with the LABELs in the same layout area
;; as their ITEMs
(element LABEL (LABELLED-LIST-LABEL))

;; this is a bit of a fudge: without it the cross-references screw up the
;; list layout:
(element (LABEL REF) (STANDARD-PHRASE))

;; =========================== NOTES ==================================

;; NOTE contains a note or annotation
(element NOTE (STANDARD-NOTE))

;; ========================== INDEX ENTRIES ============================

;; Need advice on how to do this!  See James' split.dsl example.
;; This doesn't work:
;; For indexes, James suggests declaring special flow object classes, e.g. index-entry and
;; index, that use/link to the built-in facilities in rtf/Word.
(element DivGen
  (if (and (string? (attribute-string "type"))
           (equal? (STRING-DOWNCASE (attribute-string "type")) "toc"))
  (make-table-of-contents)
  (empty-sosofo)))

;;  (map-constructor (PQUAD) (select-elements current-root 'HEAD)))

;; INDEX is an empty element: it will be used once we can build indexes in Jade

;; DIVGEN is an empty element: it will be used once we can build indexes and
;; TOCs in Jade

;; ===================== MILESTONE TAGS ===============================

;; MILESTONE, PB and LB are by default treated as irrelevant to _this_
;; pagination of the text.  Setting *output-milestones* to #t causes them
;; to appear

;; MILESTONE is an empty element marking any boundary between sections of text
(element MILESTONE
  (if *output-milestones*
    (insert-milestone (attribute-string "unit"))
    (empty-sosofo)))

;; PB is an empty element marking a page boundary
(element PB
  (if *output-milestones*
    (insert-milestone "page")
    (empty-sosofo)))

;; LB is an empty element marking a line boundary.  We can actually do this one!
;; Note that Lou suggests putting out the actual line number (N attribute) every
;; 10 lines or so.  Problem with this is getting it in the left margin.
(element LB
  (if *output-milestones*
    (insert-linebreak (attribute-string "n"))
    (empty-sosofo)))

;; =================== BIBLIOGRAPHIC CITATIONS ==========================

(element BIBL (STANDARD-PARAGRAPH))

(element (NOTE BIBL) (STANDARD-PHRASE))

(element LISTBIBL (STANDARD-LIST))

<!-- These may need styles defining, but within BIBL they should look ok
     with the default treatment, since all punctuation should be there
     anyway.  Once we get onto supporting BIBLSTRUCT things get more
     complex:
<!ENTITY % author       'INCLUDE' >
<!ENTITY % editor       'INCLUDE' >
<!ENTITY % respStmt     'INCLUDE' >
<!ENTITY % resp         'INCLUDE' >
<!ENTITY % title        'INCLUDE' >
<!ENTITY % imprint      'INCLUDE' >
<!ENTITY % publisher    'INCLUDE' >
<!ENTITY % biblScope    'INCLUDE' >
<!ENTITY % pubPlace     'INCLUDE' >
-->

;; ================= PASSAGES OF VERSE OR DRAMA ========================

;; shouldn't L be a standard-line as well as in specific contexts?
(element L (HIGHLIGHTED-LINE "CENTRE" "ITALIC" 2))

(element (LG L) (STANDARD-LINE))

(element SP
  (STANDARD-LINE-GROUP))

(element (SP L) (STANDARD-LINE))

(element SPEAKER
  (BOLD-SEQUENCE))

(element STAGE
  (ITALIC-SEQUENCE))


;; ===================== DEFAULT TEXT STRUCTURE ======================


(element TEXT
  (process-children-trim))

(element FRONT
  (process-children-trim))

(element BODY
;; was: (DISPLAYDIV (attribute-string "rend")))
 (process-children-trim))

(element GROUP
  (process-children-trim))

(element BACK
  (process-children-trim))


;; ....................... DIVISIONS OF THE BODY ......................

(element DIV (DISPLAYDIV (attribute-string "rend")))

(element (DIV HEAD) (OUTPUTHEADING 3))

(element DIV0 (DISPLAYDIV (attribute-string "rend")))

(element DIV1 (DISPLAYDIV (attribute-string "rend")))

(element (DIV1 HEAD) (OUTPUTHEADING 4))

(element DIV2 (DISPLAYDIV (attribute-string "rend")))

(element (DIV2 HEAD) (OUTPUTHEADING 3))

(element DIV3 (DISPLAYDIV (attribute-string "rend")))

(element (DIV3 HEAD) (OUTPUTHEADING 2))

(element DIV4 (DISPLAYDIV (attribute-string "rend")))

(element (DIV4 HEAD) (OUTPUTHEADING 1))

(element DIV5 (DISPLAYDIV (attribute-string "rend")))

(element (DIV5 HEAD) (OUTPUTHEADING 1))

(element DIV6 (DISPLAYDIV (attribute-string "rend")))

(element (DIV6 HEAD) (OUTPUTHEADING 1))

(element DIV7 (DISPLAYDIV (attribute-string "rend")))

(element (DIV7 HEAD) (OUTPUTHEADING 1))

;; ............ ELEMENTS COMMON TO ALL DIVISIONS ......................

(element HEAD (ITALIC-CENTRED-PARAGRAPH))

(element EPIGRAPH (ITALIC-CENTRED-PARAGRAPH))

(element ARGUMENT (ITALIC-CENTRED-PARAGRAPH))

(element OPENER (ITALIC-CENTRED-PARAGRAPH))

(element TRAILER (ITALIC-CENTRED-PARAGRAPH))

(element CLOSER (ITALIC-CENTRED-PARAGRAPH))

(element BYLINE (ITALIC-CENTRED-PARAGRAPH))

(element DATELINE (STANDARD-PARAGRAPH))

(element SALUTE (STANDARD-PARAGRAPH))

(element SIGNED (ITALIC-CENTRED-PARAGRAPH))

;; ....................... FRONT MATTER ...........................

(element TITLEPAGE (DISPLAYDIV (attribute-string "rend")))

(element DOCTITLE (OUTPUT-UNNUMBERED-HEADING 5))

(element (DOCTITLE TITLEPART) (OUTPUT-UNNUMBERED-HEADING 5))

(element TITLEPART (OUTPUT-UNNUMBERED-HEADING 3))

(element DOCAUTHOR (OUTPUT-UNNUMBERED-HEADING 3))

(element DOCEDITION (OUTPUT-UNNUMBERED-HEADING 2))

(element DOCIMPRINT (OUTPUT-UNNUMBERED-HEADING 2))

(element DOCDATE (OUTPUT-UNNUMBERED-HEADING 2))


;; =================== ADDITIONAL TAG SETS ========================

;; =========== LINKING, SEGMENTATION AND ALIGNMENT ================

;; to be dealt with when Jade can support extended pointers:
<!--
<!ENTITY % xref         'INCLUDE' >
<!ENTITY % xptr         'INCLUDE' >
<!ENTITY % seg          'INCLUDE' >
<!ENTITY % anchor       'INCLUDE' >
-->

;; =============== SIMPLE ANALYTIC MECHANISMS =====================

;; these don't require any special layout:
<!--
<!ENTITY % interp       'INCLUDE' >
<!ENTITY % interpGrp    'INCLUDE' >
<!ENTITY % s            'INCLUDE' >
-->

;; ============================ TABLES ===============================

(element TABLE (STANDARD-TABLE))

(element (TABLE HEAD) (TABLE-HEADING))

;; ignore embedded TABLE elements:
(element (TABLE ROW TABLE) (process-children-trim))

(element ROW (STANDARD-ROW))

(element CELL (STANDARD-CELL))

;; ============================= FORMULAE ===============================

;; no ideas on this one: block for display?

;; ============================= GRAPHICS ===============================

;; Note that DSSSL does not currently support text flowed around an
;;   object, so the action of the ALIGN attribute is merely to shift the
;;   image to the left or right.  An extension to add runarounds to DSSSL
;;   has been proposed and should be incorporated here when it becomes
;;   final.

(element FIGURE (STANDARD-FIGURE))

;; ======================== TAG SET DOCUMENTATION ========================

;; not in the basic TEI Lite, but part of the "TEI-internal flavour" version.

<!-- still to do:
<!ENTITY % tag          'INCLUDE' >
<!ENTITY % val          'INCLUDE' >
-->

(element GI (DELIMITED-PHRASE "<" ">"))

(element ATT (HIGHLIGHTED-PHRASE "bold"))

(element EG (MONOPARA))

;; IDENT and KW are not in the tei-lite.mod file, so are not 'guarded':
(element IDENT (HIGHLIGHTED-PHRASE "bold"))
(element KW (HIGHLIGHTED-PHRASE "bold"))

;; ============================== UNITS ================================

(define-unit mm .001m)
(define-unit cm .01m)
(define-unit in 2.54cm)
(define-unit pi (/ 1in 6))
(define-unit pt (/ 1in 72))
(define-unit px (/ 1in 96))

;; see below for definition of "em"


;; =========================== PARAMETERS ==============================

;; TEI-specific options are set by these parameters:

(define *output-milestones* #f)
(define *output-original* #f)

;; Visual acuity levels are "normal", "presbyopic", and "large-type"

(define *visual-acuity* "normal")

(define *bf-size*
  (case *visual-acuity*
	(("normal") 10pt)
	(("presbyopic") 12pt)
	(("large-type") 24pt)))
;; this value has been rather arbitrarily chosen to ensure that the TEIU5
;; examples don't do a line-wrap in the rtf result:
(define *mf-size* (- *bf-size* 3pt))
(define-unit em *bf-size*)

;; these font selections are for Windows 95

(define *title-font-family* "Arial")
(define *body-font-family* "Times New Roman")
(define *mono-font-family* "Courier New")

;; special characters to be inserted into the output.  These entities are
;; represented as Unicode hexadecimal character values, which Jade can interpret
;; directly:
(define *disk-bullet* "\U-2022")
(define *triangle-bullet* "\U-2023")
(define *circle-bullet* "\U-25CF")
(define *square-bullet* "\U-2580")
(define *small-diamond-bullet* "\U-25C6")
(define *ldquo* "\left-double-quotation-mark")
(define *rdquo* "\right-double-quotation-mark")
(define *emsp* "\U-1F9F")


(define *line-spacing-factor* 1.1)
(define *head-before-factor* 0.75)
(define *head-after-factor* 0.5)
(define *autonum-level* 6) ;; zero disables autonumbering

;; switch for paper type: currently suppports A4 and U.S. letter

(define *paper-type* "A4")
; (define *paper-type* "USletter")

(define *page-width*
  (case *paper-type*
	(("A4") 8.25in)
	(("USletter") 8.5in)))

(define *page-height*
  (case *paper-type*
	(("A4") 11.5in)
	(("USletter") 11in)))

(define *left-right-margin* 6pi)
(define *top-margin* (if (equal? *visual-acuity* "large-type")
			 9pi
		         7.5pi))
(define *bottom-margin* (if (equal? *visual-acuity* "large-type")
			 9pi
		         7.5pi))
(define *header-margin* (if (equal? *visual-acuity* "large-type")
			    6pi
			    4.5pi))
(define *footer-margin* 4.5pi)

(define *text-width* (- *page-width* (* *left-right-margin* 2)))
(define *body-start-indent* 3pi)
(define *body-width* (- *text-width* *body-start-indent*))
(define *para-sep* (/ *bf-size* 2.0))
(define *block-sep* (* *para-sep* 2.0))
(define *hsize-bump-factor* 1.2)
(define *ss-size-factor* 0.6)
(define *ss-shift-factor* 0.4)

(define *rgb-color-space*
  (color-space "ISO/IEC 10179:1996//Color-Space Family::Device RGB"))

(define *midnight-blue-color*
  (color *rgb-color-space* (/ 25 255) (/ 25 255) (/ 112 255)))
(define *grey*
  (color *rgb-color-space* (/ 2 255) (/ 2 255) (/ 2 255)))

;; ============================ FUNCTIONS ==============================

(define (expt b n)
  (if (= n 0)
      1
      (* b (expt b (- n 1)))))

(define upperalpha
  (list #\A #\B #\C #\D #\E #\F #\G #\H #\I #\J #\K #\L #\M
	#\N #\O #\P #\Q #\R #\S #\T #\U #\V #\W #\X #\Y #\Z))

(define loweralpha
  (list #\a #\b #\c #\d #\e #\f #\g #\h #\i #\j #\k #\l #\m
	#\n #\o #\p #\q #\r #\s #\t #\u #\v #\w #\x #\y #\z))

(define (ISALPHA? c)
   (if (or (member c upperalpha) (member c loweralpha)) #t #f))

(define (EQUIVLOWER c a1 a2)
  (cond ((null? a1) '())
	((char=? c (car a1)) (car a2))
	((char=? c (car a2)) c)
	(else (EQUIVLOWER c (cdr a1) (cdr a2)))))

(define (char-downcase c)
  (EQUIVLOWER c upperalpha loweralpha))

(define (LOCASE slist)
  (if (null? slist)
      '()
      (cons (char-downcase (car slist)) (LOCASE (cdr slist)))))

(define (STR2LIST s)
  (let ((start 0)
	(len (string-length s)))
    (let loop ((i start) (l len))
	 (if (= i len)
	     '()
	      (cons (string-ref s i) (loop (+ i 1) l))))))

(define (LIST2STR x)
  (apply string x))

(define (STRING-DOWNCASE s)
  (LIST2STR (LOCASE (STR2LIST s))))

(define (UNAME-START-INDEX u last)
  (let ((c (string-ref u last)))
    (if (ISALPHA? c)
	(if (= last 0)
	    0
	    (UNAME-START-INDEX u (- last 1)))
        (+ last 1))))

;; this doesn't deal with "%" yet

(define (PARSEDUNIT u)
 (if (string? u)
  (let ((strlen (string-length u)))
    (if (> strlen 2)
	(let ((u-s-i (UNAME-START-INDEX u (- strlen 1))))
	  (if (= u-s-i 0) ;; there's no number here
	      1pi         ;; so return something that might work
	      (if (= u-s-i strlen)           ;; there's no unit name here
		  (* (string->number u) 1px) ;; so default to pixels (3.2)
		  (let* ((unum (string->number
			       (substring u 0 u-s-i)))
			 (uname (STRING-DOWNCASE
				 (substring u u-s-i strlen))))
		    (case uname
			  (("mm") (* unum 1mm))
			  (("cm") (* unum 1cm))
			  (("in") (* unum 1in))
			  (("pi") (* unum 1pi))
			  (("pc") (* unum 1pi))
			  (("pt") (* unum 1pt))
			  (("px") (* unum 1px))
			  (("barleycorn") (* unum 2pi)) ;; extensible!
			  (else
			   (cond 
			    ((number? unum)
			     (* unum 1px))
			    ((number? (string->number u))
			     (* (string->number u) 1px))
				 (else u))))))))
        (if (number? (string->number u))
	    (* (string->number u) 1px)
	    1pi)))
    1pi))

(define (INLIST?)
  (or
    (equal? (gi (parent (parent))) "LIST")
    (equal? (gi (parent (parent))) "LISTBIBL")))

;; This is _incorrect_, since it doesn't allow (for a start) for lists with a
;; HEAD element.  What we want is an expression to test for a previous sibling
;; having gi = LABEL:
(define (LABELLED-LIST?)
  (equal?
    (first-child-gi (parent))
    "LABEL"))

(define (ORDERED-LIST-ITEM?)
  (equal?
    (STRING-DOWNCASE (attribute-string "type" (parent)))
    "ordered"))

(define (TOP-LEVEL-DIV?)
  (or
    (equal? (gi) "FRONT")
    (equal? (gi) "BODY")
    (equal? (gi) "BACK")
    (equal? (gi (parent)) "FRONT")
    (equal? (gi (parent)) "BODY")
    (equal? (gi (parent)) "BACK")))

(define (HSIZE n)
  (* *bf-size*
    (expt *hsize-bump-factor* n)))

(define (OLSTEP)
  (case (modulo (length (hierarchical-number-recursive "LIST")) 4)
	((1) 1.2em)
	((2) 1.2em)
	((3) 1.6em)
	((0) 1.4em)))

(define (ULSTEP) 1em)

(define (INHERITED-FONT-VALUE font-attribute)
  (case font-attribute
    (("weight") (inherited-font-weight))
    (("posture") (inherited-font-posture))))

(define (ALIGN alignment)
  (case alignment
        (("LEFT") 'start)
        (("START") 'start)
	(("CENTER") 'center)
	(("CENTRE") 'center)
	(("RIGHT") 'end)
	(("END") 'end)
	(else (inherited-quadding))))

(define (PQUAD)
  (case (attribute-string "rend")
	(("LEFT") 'start)
	(("CENTER") 'center)
	(("RIGHT") 'end)
	(else (inherited-quadding))))

(define (HQUAD)
  (cond
   ((string? (attribute-string "rend")) (PQUAD))
   (else 'center)))

(define (EMPH-WEIGHT emphasis)
  (if (string? emphasis)
    (case (STRING-DOWNCASE emphasis)
          (("light") 'light)
          (("li") 'light)
          (("bo") 'bold)
          (("bold") 'bold)
          (("sc") 'bold) ; best we can do for small caps for now: see the glyph-id property
          (else 'medium))
    'medium))

(define (EMPH-POSTURE emphasis)
  (if (string? emphasis)
    (case (STRING-DOWNCASE emphasis)
          (("oblique") 'oblique)
          (("ob") 'oblique)
          (("italic") 'italic)
          (("it") 'italic)
          (else 'upright))
    'upright))

(define (BULLSTR sty)
  (case sty
	(("CIRCLE") *circle-bullet*)
	(("SQUARE") *square-bullet*)
	(else *circle-bullet*)))

(define p-style
  (style
   font-size: *bf-size*
   line-spacing: (* *bf-size* *line-spacing-factor*)))

(define (DISPLAYDIV align)
  (if
    (TOP-LEVEL-DIV?)
    (STANDARD-PAGE-SEQUENCE)
    (make display-group
          quadding: (case align
	            	  (("LEFT") 'start)
			  (("CENTER") 'center)
			  (("RIGHT") 'end)
			  (else 'justify))
	   (process-children-trim))))

(define (number-clause-sosofo node)
  (literal
   (format-number-list (reverse (number-clause node))
		       "1"
		       ".")))

(define (number-clause node)
  (case (gi node)
    (("DIV4" "DIV3" "DIV2")
     (cons (child-number node)
	   (number-clause (parent node))))
    (("DIV1")
     (list (child-number node)))
    (("DIV")
     (if (TOP-LEVEL-DIV?)
         (list (child-number node))
         (cons (child-number node)
   	       (number-clause (parent node)))))
    (("TABLE")
     (list 1))
    (("GI")
     (list 1))
    (("LABEL")
     (list 1))
    (("LIST")
     (list 1))
    (else (list))))

;; ==================== TEI-SPECIFIC EXPRESSIONS =======================

;; This is a 'library' of expressions that can be called from the actual
;; element rules in TEI-LITE.DSL.  The intention is that the low-level
;; coding happens here (or above, in the library of low-level support
;; routines), not in TEI-LITE.DSL.  It is also the intention that users
;; can 'switch off' the standard treatment of individual elements, and
;; replace it by their own code, which can use these routines if
;; appropriate.

;; Anything below this point is a considered attempt at a set of expressions
;; for TEI Lite.  (Anything above it is copied from Jon Bosak's DSSSL style
;; sheet for HTML, and may not be optimal for this application.  i.e. if
;; you feel the need to re-write anything above this point, go ahead!)

;; PROCESS-RENDITION: deals with default REND values in a reasonable way.
;; It is guarded by a marked section so that users can replace this
;; processing if their use of REND differs dramatically from the norm.

;; this could be extended to deal with values like 'gothic' which might
;; affect typeface instead of font posture or weight:
(define (PROCESS-RENDITION target)
  (cond ((string? (attribute-string "rend"))
    (case (attribute-string "rend")
                            (("") #f)
                            (("bold") 'bold)
                            (("italic") 'italic)
                            (("BOLD") 'bold)
                            (("ITALIC") 'italic)
                            (else (INHERITED-FONT-VALUE target))))
    (else (INHERITED-FONT-VALUE target))))

;; ====================== PAGE SEQUENCES =========================

;; this could be refined, e.g. to pick up the DOCTITLE element if there
;; is no TEIHEADER:
(mode doc-heading
  (element TEI.2 (process-children-trim))
  (element TEIheader (process-children-trim))
  (element fileDesc (process-children-trim))
  (element titleStmt (process-children-trim))
  (element title (process-children-trim))
  (default (empty-sosofo)))

(mode page-heading
  (element HEAD (process-children-trim)))

(define (CURRENT-SECTION-HEADING)
  (make sequence
	font-size: (- *bf-size* 1pt)
	line-spacing: (* (- *bf-size* 1pt) *line-spacing-factor*)
	font-posture: 'italic
        (with-mode page-heading
	  (process-first-descendant "HEAD"))))

(define (DOCUMENT-TITLE-HEADING)
  (make sequence
	font-size: (- *bf-size* 1pt)
	line-spacing: (* (- *bf-size* 1pt) *line-spacing-factor*)
	font-posture: 'italic
        (with-mode doc-heading
          (process-node-list (ancestor "tei.2" (current-node))))))

(define (PAGE-NUMBER-HEADING)
  (make sequence
	font-size: (- *bf-size* 1pt)
	line-spacing: (* (- *bf-size* 1pt) *line-spacing-factor*)
  	(literal "Page ")
	(page-number-sosofo)))

;; This is the start of an attempt to output roman page numbers in the front matter.
;; It is pointless at present, since you can't reset page numbers to 1 at the start
;; of the body element until the page-sequence flow object class is supported:
;;        (if (or (have-ancestor? "BODY") (have-ancestor? "BACK"))
;;          (make sequence
;;  	    (literal "Page ")
;;	    (page-number-sosofo))
;;          (literal
;; This line doesn't work, since page-number-sosofo is an indirect flow object, not a number:
;;            (format-number (page-number-sosofo) "i")))))

(define (STANDARD-PAGE-SEQUENCE)
 (make simple-page-sequence
       font-family-name: *body-font-family*
       font-size: *bf-size*
       font-weight: 'medium
       font-posture: 'upright
       line-spacing: (* *bf-size* *line-spacing-factor*)
       left-header: (CURRENT-SECTION-HEADING)
       left-footer: (DOCUMENT-TITLE-HEADING)
       right-footer: (PAGE-NUMBER-HEADING)
       top-margin: *top-margin*
       bottom-margin: *bottom-margin*
       left-margin: *left-right-margin*
       right-margin: *left-right-margin*
       header-margin: *header-margin*
       footer-margin: *footer-margin*
       page-width: *page-width*
       page-height: *page-height*
       input-whitespace-treatment: 'collapse
       quadding: 'justify
       content-map: '((endnotes #f))
       (make sequence
             (process-children-trim))))

(define (UNNUMBERED-PAGE-SEQUENCE)
 (make simple-page-sequence
       font-family-name: *body-font-family*
       font-size: *bf-size*
       font-weight: 'medium
       font-posture: 'upright
       line-spacing: (* *bf-size* *line-spacing-factor*)
       top-margin: *top-margin*
       bottom-margin: *bottom-margin*
       left-margin: *left-right-margin*
       right-margin: *left-right-margin*
       header-margin: *header-margin*
       footer-margin: *footer-margin*
       page-width: *page-width*
       page-height: *page-height*
       input-whitespace-treatment: 'collapse
       quadding: 'justify
       (process-children-trim)))

;; ========================= PARAGRAPH STYLES =======================

(define (STANDARD-PARAGRAPH)
 (make paragraph
       use: p-style
       space-before: *para-sep*
       start-indent: *body-start-indent*
       quadding: (PQUAD)
       (process-children-trim)))

(define (ITALIC-CENTRED-PARAGRAPH)
  (make paragraph
	use: p-style
	space-before: (* *para-sep* 2)
	quadding: 'center
	font-posture: 'italic
	(process-children-trim)))

(define (MONOPARA)
  (make paragraph
        line-spacing: (* *bf-size* *line-spacing-factor*)
	space-before: *para-sep*
	start-indent: (+ *body-start-indent* 1em)
        lines: 'asis
	font-family-name: *mono-font-family*
	font-size: *mf-size*
	input-whitespace-treatment: 'preserve
        (process-children-trim)))

(define (STANDARD-PHRASE)
  (make sequence
        font-weight: (PROCESS-RENDITION "weight")
        font-posture: (PROCESS-RENDITION "posture")
        (process-children-trim)))

(define (STANDARD-PHRASE-WITH-SUFFIX suffix)
  (make sequence
        font-weight: (PROCESS-RENDITION "weight")
        font-posture: (PROCESS-RENDITION "posture")
        (process-children-trim)
        (literal suffix)))

(define (DELIMITED-PHRASE prefix suffix)
  (make sequence
        font-weight: (PROCESS-RENDITION "weight")
        font-posture: (PROCESS-RENDITION "posture")
        (literal prefix)
        (process-children-trim)
        (literal suffix)))

(define (HIGHLIGHTED-PHRASE rend)
  (make sequence
        font-weight: (EMPH-WEIGHT rend)
        font-posture: (EMPH-POSTURE rend)
        (process-children-trim)))

(define (UNCLEAR-PHRASE)
  (make sequence
        font-weight: 'ultra-light
        color: *grey*
        font-posture: (PROCESS-RENDITION "posture")
        (process-children-trim)))

;; STANDARD-LINE-GROUP, STANDARD-LINE and OTHER-LINE contributed by Nigel
;; Kerr:

(define (STANDARD-LINE-GROUP)
  (make paragraph
	use: p-style
	space-before: (* *para-sep* 2)
	start-indent: (* *body-start-indent* 2)
	quadding: 'start
	(process-children-trim)))

(define (STANDARD-LINE)
  (make paragraph
	use: p-style
	space-before: 0pt
	quadding: 'start
	(process-children-trim)))

(define (ITALIC-LINE)
  (make paragraph
	use: p-style
	space-before: 0pt
	quadding: 'start
	font-posture: 'italic
	(process-children-trim)))

(define (HIGHLIGHTED-LINE alignment emphasis separation-factor)
  (make paragraph
	use: p-style
	space-before: (* *para-sep* separation-factor)
	quadding: (ALIGN alignment)
	font-weight: (EMPH-WEIGHT emphasis)
	font-posture: (EMPH-POSTURE emphasis)
	(process-children-trim)))

;; treatment of NOTE-type elements is pretty simple at present.  The current
;; Jade engine does not support the more complex page model, so there is
;; no point in trying to get notes to appear at the foot of the page,
;; chapter, etc.  They are just output as a block at the end of the DIV1.

(define (NOTE-HEADER)
   (make sequence
         label: 'endnotes
         (make rule
               orientation: 'horizontal
               space-before: *para-sep*
               start-indent: *left-right-margin*
               end-indent: *left-right-margin*
               display-alignment: 'center)
         (make paragraph
               use: p-style
               start-indent: *body-start-indent*
               space-before: *para-sep*
               font-weight: 'bold
               (literal "Notes:"))))

;; STANDARD-NOTE outputs a reference to the note in the current position, and
;; places the note itself at the end of the section.  (This relies on the
;; definition of STANDARD-PAGE-SEQUENCE including a mapping for the endnotes
;; label.)
(define (STANDARD-NOTE)
  (make sequence
    (make line-field
          position-point-shift: 2pt
          font-size: (- *bf-size* 2pt)
          font-weight: 'bold
          (literal
            (string-append "["
              (format-number-list
                (element-number-list
                  (cond
                    ((have-ancestor? "DIV1") (list "DIV1" "NOTE"))
                    ((have-ancestor? "DIV") (list "DIV" "NOTE"))
                    (else (list "NOTE"))))
                 "1" ".") "]")))
    (make sequence
          label: 'endnotes
;; (car (cdr below can be replaced by (cadr once implemented.  (This gets the second number
;; in the list, i.e. the count of NOTE elements within the DIV):
          (if (= (car( cdr (element-number-list (list "DIV1" "NOTE")))) 1)
              (NOTE-HEADER)
              (empty-sosofo)))
    (make paragraph
          label: 'endnotes
          use: p-style
          font-size: (- *bf-size* 2pt)
          start-indent: *body-start-indent*
          line-spacing: (- (* *bf-size* *line-spacing-factor*) 2pt)
          (literal
            (string-append
              (format-number-list
                (element-number-list
                  (cond
                    ((have-ancestor? "DIV1") (list "DIV1" "NOTE"))
                    ((have-ancestor? "DIV") (list "DIV" "NOTE"))
                    (else (list "NOTE"))))
                "1" ".") ".  "))
          (process-children-trim))))


;; this could be refined to pick up the REND attribute and output appropriate
;; start and end characters (see Guidelines 6.3.3, p. 150).
(define (QUOTED-PHRASE)
  (make sequence
     (literal *ldquo*)
     (process-children-trim)
     (literal *rdquo*)))

(define (OUTPUT-GAP replacement-string)
  (make sequence
        font-posture: 'italic
        (literal " [")
        (if (string? replacement-string)
            (literal replacement-string)
            (literal " ..."))
        (literal "]")))

(define (STANDARD-GAP)
  (OUTPUT-GAP (attribute-string "reason")))

;; DELETED-TEXT is used to render the DEL element.  It currently just
;; uses the strike-through font style, but could take account of the
;; values for REND indicated in the Guidelines (p922-3)
(define (DELETED-TEXT)
        (make sequence
          (make score
                type: 'through
                (process-children-trim))))

;; ................ [DIVn] Headings  .................

(define (OUTPUTHEADING headsize)
  (make paragraph
	font-family-name: *title-font-family*
	font-weight: 'bold
	font-size: (HSIZE headsize)
	line-spacing: (* (HSIZE headsize) *line-spacing-factor*)
	space-before: (* (HSIZE headsize) *head-before-factor*)
	space-after: (* (HSIZE headsize) *head-after-factor*)
	quadding: (HQUAD)
	keep-with-next?: #t
        (if (have-ancestor? "BODY") ; only body sections are numbered
          (make sequence
            (number-clause-sosofo (parent (current-node)))
            (literal " "))
          (empty-sosofo))
	(process-children-trim)))

(define (OUTPUT-UNNUMBERED-HEADING headsize)
  (make paragraph
	font-family-name: *title-font-family*
	font-weight: 'bold
	font-size: (HSIZE headsize)
	line-spacing: (* (HSIZE headsize) *line-spacing-factor*)
	space-before: (* (HSIZE headsize) *head-before-factor*)
	space-after: (* (HSIZE headsize) *head-after-factor*)
	quadding: (HQUAD)
	keep-with-next?: #f
	(process-children-trim)))

;; ................... links and cross references ................

(define (LINK-WITH-TARGET-CONTENT)
  (with-mode ptr
    (process-element-with-id (attribute-string "target"))))

(mode ptr
   (element HEAD
      (handle-head-ptr
         (with-mode title-ref
            (process-node-list (current-node)))))
   (element DIV
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV1
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV2
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV3
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV4
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV5
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV6
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD))))
   (element DIV7
      (handle-ptr
         (with-mode title-ref
            (process-first-descendant 'HEAD)))))

(define (handle-ptr title-sosofo)
  (sosofo-append
   (literal "see ")
   (number-clause-sosofo (current-node))
   (literal ", ")
   (make link
	 destination: (current-node-address)
	 color: *midnight-blue-color*
	 font-posture: 'italic
	 (make score
	       type: 'after
	       title-sosofo))
   (literal ", page ")
   (current-node-page-number-sosofo)))

;; this variant is for the case where it is the head element, rather than its containing
;; div, which has the target ID:
(define (handle-head-ptr title-sosofo)
  (sosofo-append
   (literal "see ")
   (number-clause-sosofo (parent (current-node)))
   (literal ", ")
   (make link
	 destination: (current-node-address)
	 color: *midnight-blue-color*
	 font-posture: 'italic
	 (make score
	       type: 'after
	       title-sosofo))
   (literal ", page ")
   (current-node-page-number-sosofo)))

(mode title-ref
      (default (process-children-trim)))

(define (SIMPLE-CROSS-REFERENCE)
  (if (string? (attribute-string "target"))
   (make link
         destination: (idref-address (attribute-string "target"))
	 color: *midnight-blue-color*
	 font-posture: 'italic
         (make score
               type: 'after
               (process-children-trim))
         (make sequence
            (with-mode ref
              (process-element-with-id (attribute-string "target")))))
   (empty-sosofo)))

(mode ref
   (default
      (handle-ref)))

(define (handle-ref)
  (sosofo-append
   (literal ", page ")
   (current-node-page-number-sosofo)
   (literal " ")))

;; ...................... lists ...............................

(define (STANDARD-LIST)
 (make paragraph
       space-before: (if (INLIST?)
			 *para-sep*
		         *block-sep*)
       space-after:  (if (INLIST?)
			 *para-sep*
		         *block-sep*)
       start-indent: (if (INLIST?)
			 (+ (inherited-start-indent) (ULSTEP))
		         *body-start-indent*)
       (process-children-trim)))

;; note that labelled lists pose a problem if you want to have the heading
;; (LABEL) and value (ITEM) in the same paragraph flow object, since there
;; is no 'container' element which can be associated with that object.
;; This has been dealt with by using the (deprecated) paragraph-break flow object:
(define (LABELLED-LIST-LABEL)
 (make sequence
  (make paragraph-break
        use: p-style
        space-before: *para-sep*
        start-indent: (+ (inherited-start-indent) (ULSTEP))
        first-line-start-indent: (- (ULSTEP)))
  (HIGHLIGHTED-PHRASE "BOLD")
  (make line-field
	font-family-name: *body-font-family*
	font-size: *bf-size*
        field-align: 'end
	field-width: (ULSTEP)
	input-whitespace-treatment: 'preserve
;; this is a fudge because you can't put emsp in directly:
        (literal "  "))))
;;        (literal *emsp*))))

(define (STANDARD-LIST-ITEM)
  (if (LABELLED-LIST?)
      (LABELLED-LIST-ITEM)
      (INDENTED-LIST-ITEM)))

(define (LABELLED-LIST-ITEM)
 (make sequence
       (process-children-trim)))

(define (INDENTED-LIST-ITEM)
 (if (ORDERED-LIST-ITEM?)
     (ORDERED-LIST-ITEM)
 (make paragraph
       use: p-style
       space-before: *para-sep*
       start-indent: (inherited-start-indent)
       (make line-field
	     font-family-name: *body-font-family*
	     font-size: *bf-size*
	     field-width: (ULSTEP)
	     (literal *circle-bullet*))
       (process-children-trim))))

(define (ORDERED-LIST-ITEM)
 (make paragraph
       use: p-style
       space-before: *para-sep*
       start-indent: (+ (inherited-start-indent) (OLSTEP))
       first-line-start-indent: (- (OLSTEP))
       (make line-field
	     field-width: (OLSTEP)
	     (literal
              (if (string? (attribute-string "n"))
                  (attribute-string "n")
  	          (case (modulo (length
		    (hierarchical-number-recursive "LIST")) 4)
		      ((1) (string-append
		      	    (format-number
			     (child-number) "1")
			    "."))
   		      ((2) (string-append
			    (format-number
			     (child-number) "a")
			    "."))
		      ((3) (string-append
			    "("
			    (format-number
			     (child-number) "i")
			    ")"))
		      ((0) (string-append
			    "("
			    (format-number
			     (child-number) "a")
			    ")"))))))
       (process-children-trim)))

;; ........................... TABLES ................................

(define (STANDARD-TABLE)
  (make display-group
	content-map: '((caption #f))
	(make table
              keep: 'page
              space-before: *para-sep*
	      start-indent: *body-start-indent*
	      (make sequence
		    start-indent: 0pt))))

(define (TABLE-HEADING)
 (make paragraph
       label: 'caption
       use: p-style
       font-weight: 'bold
       space-before: *para-sep*
       space-after: (/ *para-sep* 2.0)
       start-indent: *body-start-indent*
       (literal
	(string-append
	 "Table "
	 (format-number
	  (element-number) "1")
	 ". "))
       (process-children-trim)))

(define (STANDARD-ROW)
 (make table-row
       (process-children-trim)))

(define (STANDARD-CELL)
 (make table-cell
       n-columns-spanned: (if (attribute-string "COLS")
                              (string->number (attribute-string "COLS"))
                              1)
       (make paragraph
	     font-weight: (if (equal? (STRING-DOWNCASE (attribute-string "ROLE")) "label")
                              'bold
                              'medium)
	     space-before: 0.25em
	     space-after: 0.25em
	     start-indent: 0.25em
	     end-indent: 0.25em
	     quadding: 'start
	     (process-children-trim))))

;; ........................... FIGURES ................................

;; the notation-system-id statement currently gives Jade parsing errors,
;; but the actual image is displayed (at least for a GIF image):
(define (STANDARD-FIGURE)
  (make external-graphic
    display?: #t
    space-before: 1em
    space-after: 1em
    display-alignment: (PQUAD)
;;    notation-system-id: (notation-generated-system-id
;;                         (entity-notation
;;                          (attribute-string "ENTITY")))
    entity-system-id: (entity-generated-system-id
                (attribute-string "ENTITY"))))


;; ======================== INLINE ELEMENTS ==========================

(define (BOLD-SEQUENCE)
  (make sequence
    font-weight: 'bold
    (process-children-trim)))

(define (ITALIC-SEQUENCE)
  (make sequence
    font-posture: 'italic
    (process-children-trim)))

(define (MONO-SPACE-SEQUENCE)
  (make sequence
	font-family-name: *mono-font-family*
	font-size: *mf-size*
	(process-children-trim)))

(define (insert-milestone milestone-unit)
  (make sequence
    (make paragraph-break)
    (make line-field
          field-width: *body-width*
          field-align: 'center
          font-family-name: *body-font-family*
          font-size: *bf-size*
          (literal
            (string-append
              "- - - - - - - - - - - - - - - - ["
              (if (string? milestone-unit)
                milestone-unit
                "")
              " "
              (if (string? (attribute-string "n"))
                (attribute-string "n")
                "")
              "] - - - - - - - - - - - - - - - -")))
    (make paragraph-break)))

;; insert-linebreak just breaks the line where it occurs:
(define (insert-linebreak line-number)
  (make paragraph-break))

;; this is a fancier version, which has the correct logic to output a line number every
;; 10th line.  However, the paragraph-break flow-object means that this line number appears
;; within the margin of the page layout.  We need to be able to get it into the left (or right!)
;; margin.  I don't think that Jade can currently support this.
;;  (define (insert-linebreak line-number)
;;    (if (and (string? line-number) (equal? (modulo (string->number line-number) 10) 0))
;;      (make sequence
;;        (make paragraph-break)
;;        (make line-field
;;              field-width: *left-right-margin*
;;              (literal line-number)))
;;      (make paragraph-break)))

;;==============================TABLE OF CONTENTS==================================

;; (Large-type tables of contents don't work properly: the cells aren't wide enough for
;;  wrapped-around entries, and the page number is in the standard font size.)
(define (make-table-of-contents)
  (make table
        start-indent: *body-start-indent*
        use: p-style
        (with-mode toc
          (process-node-list (ancestor "tei.2" (current-node))))))

(define (toc-entry)
  (make sequence
;; Considerable effort went into trying to get the section number to be right-justified
;; with its cell, but introducing a paragraph flow object caused each character to appear
;; on a separate line, at the right-hand edge of the cell, even if the paragraph was left-
;; justified!  Any ideas on this one are welcomed.
    (make table-cell
          starts-row?: #t
          cell-before-row-margin: (/ *bf-size* 2)
          (number-clause-sosofo (parent (current-node))))
    (make table-cell
          cell-before-row-margin: (/ *bf-size* 2)
          n-columns-spanned: (if (equal? *visual-acuity* "large-type")
                                 5   ; 5/7 of width for large-type
                                 8) ; 8/10 of width goes to heading; 1/10 to section and page number!
          (make sequence
            (literal "  ")
            (STANDARD-PHRASE)))
    (make table-cell
          ends-row?: #t
; for some reason this causes the page number to be half out of the cell:
;          cell-before-row-margin: (/ *bf-size* 2)
          (current-node-page-number-sosofo))))


(mode toc
  (element (DIV HEAD) (toc-entry))
  (element (DIV1 HEAD) (toc-entry))
  (element (DIV2 HEAD) (toc-entry))
  (element (DIV3 HEAD) (toc-entry))
  (element TEI.2 (process-children))
  (element TEXT (process-children))
  (element BODY (process-children))
  (element DIV (process-children))
  (element DIV1 (process-children))
  (element DIV2 (process-children))
  (element DIV3 (process-children))
  (default (empty-sosofo)))

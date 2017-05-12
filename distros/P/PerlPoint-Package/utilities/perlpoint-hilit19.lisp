
;; = HISTORY SECTION =====================================================================

;; ---------------------------------------------------------------------------------------
;; version | date     | author   | changes
;; ---------------------------------------------------------------------------------------
;; 0.03    |01.03.2002| JSTENZEL | added document stream entry points;
;;         |          | JSTENZEL | switched to perlpoint-... identifiers;
;; 0.02    |09.06.2001| JSTENZEL | variables can contain umlauts now, adapted;
;; 0.01    | 2000     | JSTENZEL | new.
;; ---------------------------------------------------------------------------------------

;; = CODE SECTION ========================================================================


;; This piece of code is an example how Emacs'
;; hilit19 module could be extended for a
;; perlpoint-mode. This is no part of Emacs.
;;
;; Copyright (C) 2001, 2002 Jochen Stenzel (perl@jochen-stenzel.de).


;; first: extend hilit-default-face-table (use the colors you prefer)
(defconst hilit-default-face-table
  '(
    ;; ...
    ;; (the default definitions as distributed with the original hilit-default-face-table)

    ;; PerlPoint faces
    (perlpoint-comment		ForestGreen         moccasin           italic)
    (perlpoint-variable		ForestGreen-bold    green	       bold)
    (perlpoint-headline		red-underline	    orange-underlined  underline)
    (perlpoint-condition	red-bold            yellow	       bold)
    (perlpoint-docstream	Goldenrod	    DarkGoldenrod      underline)
    (perlpoint-list-intro	red-bold            yellow	       bold)
    (perlpoint-macrodef		blue-bold	    cyan-bold	       bold-italic)
    (perlpoint-tag		RoyalBlue	    cyan	       bold-italic)
    )

  "... (the default comment)")



;; second: declare the PerlPoint patterns and assign faces
(
 hilit-set-mode-patterns 'perlpoint-mode

 '(
   ;; comment
   ("^//.*$" nil comment)

   ;; variable definition
   ("^\\$[_A-Za-z0-9‰ˆ¸ƒ÷‹ﬂ]+=" nil define)

   ;; variable usage
   ("\\$[_A-Za-z0-9‰ˆ¸ƒ÷‹ﬂ]+" nil define)
   ("\\$\\{[_A-Za-z0-9‰ˆ¸ƒ÷‹ﬂ]+\\}" nil define)

   ;; headline
   ("^=+.+$" nil label)

   ;; document stream entry point
   ("^~+.+$" nil error)

   ;; list points
   ("^*" nil error)
   ("^##?" nil error)
   ("^:.+:" nil error)

   ;; alias definition
   ("^\\++.+$" nil defun)

   ;; tags (closing angle bracket definition is too common, but as a first trial ...)
   ("\\\\[_A-Z0-9]+\\({.+}\\)?<?" nil keyword)
   (">" nil keyword)
  )
)



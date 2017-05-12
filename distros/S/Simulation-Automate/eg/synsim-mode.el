;;; synsim-mode.el --- major mode providing a synsim mode hook for fontification
;;
;;>put the file in $HOME/elisp;
;;>put this in your .emacs:
;;>
;;>;Mode for SynSim data files. 
;;>(setq auto-mode-alist (append '(("\\.data$" . synsim-mode)) auto-mode-alist))
;;>(autoload 'synsim-mode "synsim-mode" "SynSim Editing Mode" t)
;; 
;; Based on spice-mode.el 
;; Emacs Lisp Archive Entry
;; Author: Wim Vanderbauwhede <wim@motherearth.org> 2002
;;         Geert A. M. Van der Plas <geert.vanderplas@email.com> 1999,2000 
;;         Emmanuel Rouat <emmanuel.rouat@wanadoo.fr> 1997,98 
;;         Carlin J. Vieri, MIT AI Lab <cvieri@ai.mit.edu> 1994 
;; Keywords: synsim, simulation automation, datafile editing
;; Filename: synsim-mode.el
;; Version: 0.97.2
;; Maintainer: Wim Vanderbauwhede <wim@motherearth.org>
;; Last-Updated: 26 November 2002
;; Description: synsim datafile editing
;; URL: http://www.eee.strath.ac.uk/~wim/synsim.html
;; Compatibility: Emacs20, XEmacs21.1

;; Copyright (C) 1994, MIT Artificial Intelligence Lab
;; Copyright (C) 1997,98 Emmanuel Rouat
;; Copyright (C) 1999,2000 Geert A. M. Van der Plas, 
;; Copyright (C) 2002 Wim Vanderbauwhede

;; This file is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 2, or (at your option)
;; any later version.

;; This file is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs; see the file COPYING.  If not, write to
;; the Free Software Foundation, 675 Mass Ave, Cambridge, MA 02139, USA.

;; If you have any questions about this mode, feel free to contact me
;; at the following address:  geert.vanderplas@email.com. If I find the
;; time, I can take a look at the problem

;; To use synsim-mode, add either the following to your .emacs file.  This
;; assumes that you will use the .sp, .cir, ... extensions for 
;; your synsim source deck:
;; (autoload 'synsim-mode "synsim-mode" "Synsim/Layla Editing Mode" t)
;; (setq auto-mode-alist (append (list (cons "\\.data$" 'synsim-mode)) auto-mode-alist))
;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Commentary:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; This package provides an XEmacs major mode for editing SynSim data files
;; It includes the following features:

;;   - Highlighting of (extended) SYNSIM syntax, with ERROR notification
;;   - Comprehensive menu
;;   - imenu (shift right click)
;;   - Postscript printing with fontification (through ps-print package)
;;   - Works under XEmacs (Linux) (not tested under GNU Emacs, chances are that
;;      it'll work)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; TODO:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;   - ...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; BUGS:
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;   -  ...

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defconst synsim-mode-version "0.9.1 November 2002"
  "Current version of synsim mode (Synsim).")

(defconst synsim-developer 
  "Wim Vanderbauwhede <wim@motherearth.org>"
  "Current developer/maintainer of synsim-mode.")

(defgroup synsim-mode nil
  "Customizations for Synsim Mode."
  :prefix "synsim-mode-"
  :group 'languages
  :version "21.1" 
  )

(defgroup synsim-mode-style nil
  "Customizations for code styles."
  :group 'synsim-mode)

;; help function
(defun synsim-mode-custom-set (variable value &rest functions)
  "Set variables as in `custom-set-default' and call FUNCTIONS afterwards."
  (if (fboundp 'custom-set-default)
      (custom-set-default variable value)
    (set-default variable value))
  (while functions
    (when (fboundp (car functions)) (funcall (car functions)))
    (setq functions (cdr functions))))

(defun set-synsim-mode-standard ()
  "set synsim mode standard after customization"
  (message "set synsim mode standard")
  )

(defcustom synsim-mode-standard '(synsim)
  "*Synsim standards used.
Basic standard:
  Synsim      : Original BON Synsim
"
; NOTE: Activate the new setting in a Synsim buffer using the menu entry
;      \"Activate New Customizations\"."
  :type '(list (choice :tag "Basic standard"
		       (const :tag "Synsim" synsim))
	       )
  :set (lambda (variable value)
         (synsim-mode-custom-set variable value
				 'set-synsim-mode-standard
))
  :group 'synsim-mode-style)

(defgroup synsim-mode-highlight nil
  "Customizations for highlighting."
  :group 'synsim-mode)

(defcustom synsim-mode-highlight-keywords t
  "*Non-nil means highlight SYNSIM-MODE keywords and other standardized words.
The following faces are used:
  `synsim-mode-title-face'         : title (first line in a synsim file)
  `font-lock-keyword-face'        : keywords
  `font-lock-warning-face'        : warnings
  `synsim-mode-variable-face'      : variable names
  `font-lock-comment-face'        : comment
  `font-lock-type-face'           : types
  `font-lock-constant-face'       : include files
  `font-lock-variable-name-face'  : names of .param's / variables

NOTE: Activate the new setting in a synsim-mode buffer by re-fontifying it (menu
      entry \"Fontify Buffer\").  XEmacs: turn off and on font locking."
  :type 'boolean
  :set (lambda (variable value)
         (synsim-mode-custom-set variable value 'synsim-mode-font-lock-init))
  :group 'synsim-mode-highlight)

(require 'font-lock)

(defvar synsim-mode-variable-face		'synsim-mode-variable-face
  "Face name to use synsim variables.")

(defface synsim-mode-variable-face
  '((((class grayscale) (background light)) (:foreground "LightGray" :bold t))
    (((class grayscale) (background dark)) (:foreground "DimGray" :bold t))
    (((class color) (background light)) (:foreground "ForestGreen" :bold t))
    (((class color) (background dark)) (:foreground "Yellow" :bold t))
    (t (:bold t)))
  "Synsim mode face used to highlight variables."
  :group 'synsim-mode-highlight)

(defvar synsim-mode-title-face		'synsim-mode-title-face
  "Face name to use synsim TITLE.")

(defface synsim-mode-title-face
  '((((class grayscale) (background light)) (:foreground "LightGray" :bold t))
    (((class grayscale) (background dark)) (:foreground "DimGray" :bold t))
    (((class color) (background light)) 
     (:foreground "Blue" :background "LightGray" :bold t))
    (((class color) (background dark)) (:foreground "green3" :bold t))
    (t (:bold t)))
  "Synsim mode face used to highlight title."
  :group 'synsim-mode-highlight)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Font lock initialization
(defvar synsim-mode-font-lock-keywords-0 nil 
  ;; set in `synsim-mode-font-lock-init' because dependent on custom variables
  "For consideration as a value of `synsim-mode-font-lock-keywords'.
This does highlighting of keywords and standard identifiers.")

(defvar synsim-mode-font-lock-keywords-1 nil
  ;; set in `synsim-mode-font-lock-init' because dependent on custom variables
  "For consideration as a value of `synsim-mode-font-lock-keywords'.
This does highlighting of keywords and standard identifiers.")


(defun synsim-mode-font-lock-init ()
  "Initialize fontification."
  ;; highlight title
  (setq synsim-mode-font-lock-keywords-0
	 (list 
	  '("^\ *TITLE\ *:.*" 0 synsim-mode-title-face)
	  )
	 )

  ;; highlight all other stuff
  (setq synsim-mode-font-lock-keywords-1
	(list
	 '("^\\#\ *\_[A-Z0-9_]+\ *=" . font-lock-variable-name-face)
	 '("^\_[A-Z0-9_].*=" . synsim-mode-variable-face)
	 '("^\ *[A-Z0-9_]+\ *:" 0 font-lock-warning-face)
	 '("\\#\\([^+\n].*\\|\n\\)" 0 font-lock-comment-face)
	 ))

  (setq synsim-mode-font-lock-keywords 
	  (append synsim-mode-font-lock-keywords-0 ;; title first
		  synsim-mode-font-lock-keywords-1
	  )
	  )
  )

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Comments 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(defun uncomment-region (beg end)
  "Uncomment selected region - comment symbol is '*'
Doc comments (starting with '!') are unaffected."
  (interactive "r")
  (comment-region beg end -1))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; Menus
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Synsim menu (using `easy-menu.el')

(defun synsim-mode-customize ()
  "Call the customize function with `synsim-mode' as argument."
  (interactive)
  (customize-browse 'synsim-mode))

(defun synsim-create-mode-menu ()
  "Create Synsim Mode menu."
  (list
   "Synsim"
   '("Edit"
     ["Comment Region"         comment-region (mark)]
     ["Uncomment Region"       uncomment-region (mark)]
     ["Fontify..."             font-lock-fontify-buffer t]
     )

   '("Customize"
     ["Browse Synsim Group..."	synsim-mode-customize t]
     "--"
     ["Activate New Customizations" synsim-mode-activate-customizations t])
   "--"
   ["About Synsim-Mode"         synsim-about t]
   )
  )

(defvar synsim-mode-menu-list (synsim-create-mode-menu)
  "Synsim Mode menu.")

(defun synsim-about ()
  (interactive)
  (sit-for 0)
  (message "synsim-mode version %s, © %s" synsim-mode-version synsim-developer))


(defvar synsim-mode-syntax-table nil
  "Syntax table used in synsim-mode buffers.")

(if synsim-mode-syntax-table
    ()
  (setq synsim-mode-syntax-table (make-syntax-table))
  (modify-syntax-entry ?$ "<" synsim-mode-syntax-table)
  (modify-syntax-entry ?* "<" synsim-mode-syntax-table)
  (modify-syntax-entry ?_ "w" synsim-mode-syntax-table)
  (modify-syntax-entry ?\n "> b" synsim-mode-syntax-table)
  (modify-syntax-entry ?\" "\"" synsim-mode-syntax-table)
)

(defvar synsim-mode-abbrev-table nil
  "Abbrev table in use in synsim-mode buffers.")
(define-abbrev-table 'synsim-mode-abbrev-table ())

(defvar synsim-mode-map ()
  "Keymap used in synsim-mode.")
(if synsim-mode-map
    ()
  (setq synsim-mode-map (make-sparse-keymap))
;  (install-common-language-commands synsim-mode-map)
)

(require 'easymenu)

(defun synsim-update-mode-menu ()
  "Update Synsim mode menu."
  (interactive)
  (easy-menu-remove synsim-mode-menu-list) ; for XEmacs
  (setq synsim-mode-menu-list (synsim-create-mode-menu))
  (easy-menu-add synsim-mode-menu-list)	; for XEmacs
  (easy-menu-define synsim-mode-menu synsim-mode-map
		    "Menu keymap for Synsim Mode." synsim-mode-menu-list))

(require 'imenu)

(defvar synsim-imenu-generic-expression nil
  "Imenu generic expression for synsim mode.  See `imenu-generic-expression'.")

(defun synsim-mode-imenu-init ()
  "initialize imenu generic expression and pass to imenu"
  (setq synsim-imenu-generic-expression
	nil
	imenu-generic-expression synsim-imenu-generic-expression)
  )

(defun set-synsim-mode-name ()
  "Set visual name of synsim mode"
  (setq mode-name 
	"Synsim Datafile"
	)
)

(defun synsim-mode-activate-customizations ()
  "Activate all customizations on local variables."
  (interactive)
  (set-synsim-mode-name)
  (synsim-mode-imenu-init) 
  (synsim-mode-words-init)
  (synsim-mode-font-lock-init)
  (font-lock-unset-defaults)
  (setq font-lock-defaults
       (list 'synsim-mode-font-lock-keywords t t))
  (font-lock-set-defaults)
  (font-lock-fontify-buffer)
)

;; ======================================================================
;; synsim-mode main entry point
;; ======================================================================
;;;###autoload
(defun synsim-mode ()
  "Major mode for editing synsim data files. 
No bug report notification is currently available.  No indentation is
implemented; this mode does provide a font-lock hook. Autoload synsim-mode through
your .emacs file.  turning on Synsim mode calls the value of the
variable `synsim-mode-hook' with no args, if that value is non-nil."
  (interactive)
  (kill-all-local-variables)
  (use-local-map synsim-mode-map)
  (set-syntax-table synsim-mode-syntax-table)
  (setq major-mode 'synsim-mode)
  (setq mode-name "Synsim")
  (set-synsim-mode-name)
;  (set (make-local-variable 'paragraph-start) (concat "^$\\|" page-delimiter))
;  (set (make-local-variable 'paragraph-ignore-fill-prefix) t)
;  (set (make-local-variable 'parse-sexp-ignore-comments) nil)
;  (set (make-local-variable 'tempo-interactive) t)
;  (set (make-local-variable 'require-final-newline) t)
;  (set (make-local-variable 'comment-start) "#")
;  (set (make-local-variable 'comment-end) "")
;  (set (make-local-variable 'comment-start-skip) "\#")
;  (set (make-local-variable 'comment-multi-line) nil)
;  (set (make-local-variable 'fill-prefix) "+ ")
;  (set (make-local-variable 'auto-fill-inhibit-regexp) "^\*[^\.\+].*")
;  (set (make-local-variable 'fill-column) 80)

  (synsim-mode-font-lock-init)
  (set (make-local-variable 'font-lock-defaults)
       (list 'synsim-mode-font-lock-keywords t t)) ; nil -> t, don't do strings

  ;; imenu init
  (set (make-local-variable 'imenu-case-fold-search) t)
  (synsim-mode-imenu-init)

  ;; add Synsim mode menu
  (easy-menu-add synsim-mode-menu-list)	; for XEmacs
  (easy-menu-define synsim-mode-menu synsim-mode-map
		    "Menu keymap for Synsim Mode." synsim-mode-menu-list)
  ;; run synsim-mode hooks
  (run-hooks 'synsim-mode-hook)
)

;; this is sometimes useful
(provide 'synsim-mode)

;;; synsim-mode.el ends here

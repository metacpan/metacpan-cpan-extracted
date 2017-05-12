;; systemc-mode.el --- major mode for editing SystemC files
;; $VERSION = '1.344';

;; Author          : Wilson Snyder <wsnyder@wsnyder.org>
;; Keywords        : languages

;;; Commentary:
;;
;; Distributed from the web
;;	http://www.veripool.org
;;
;; To use this package, simply put it in a file called "systemc-mode.el" in
;; a Lisp directory known to Emacs (see `load-path').
;;
;; Byte-compile the file (in the systemc-mode.el buffer, enter dired with C-x d
;; then press B yes RETURN)
;;
;; Put these lines in your ~/.emacs or site's site-start.el file (excluding
;; the START and END lines):
;;
;;	---INSTALLER-SITE-START---
;;	;; Systemc mode
;;	(autoload 'systemc-mode "systemc-mode" "Mode for SystemC files." t)
;;	(setq auto-mode-alist (append (list '("\\.sp$" . systemc-mode)) auto-mode-alist))
;;	---INSTALLER-SITE-END---
;;
;; COPYING:
;;
;; Copyright 2001-2014 by Wilson Snyder.  This program is free software;
;; you can redistribute it and/or modify it under the terms of either the GNU
;; Lesser General Public License Version 3 or the Perl Artistic License Version 2.0.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;

;;; History:
;;
;; Changes in Emacs22 have made it difficult to keep up with new mode
;; requirements.  Therefore this mode has been stripped to just call
;; c++-mode.  This may be improved in the future.  Old versions with
;; the removed functionality are available from the author or CPAN.


;;; Code:

(provide 'systemc-mode)
(require 'cc-mode)

;;;;========================================================================
;;;; Variables/ Keymap

(defvar systemc-mode-hook nil
  "Run at the very end of `systemc-mode'.")


;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sp\\'" . systemc-mode))

;;;###autoload
(defun systemc-mode ()
  "Major mode for editing SystemC C++ Files.

This mode simply calls `c++-mode'.

In addition the hook `systemc-mode-hook' is run with no args at mode
initialization."
  (interactive)
  (c++-mode)
  ;;
  ;; Hooks
  (run-hooks 'systemc-mode-hook))


(provide 'systemc-mode)
;;; systemc-mode.el ends here

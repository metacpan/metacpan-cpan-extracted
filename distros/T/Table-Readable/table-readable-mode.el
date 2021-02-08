;; table-readable-mode.el --- Major mode for the Table::Readable format
(defvar table-readable-font-lock-defaults
  `((
     ("^#.*$" . font-lock-comment-face)
     ("^\\(%%\\)?[a-z]+:\\|%%" . font-lock-variable-name-face)
     )))
(define-derived-mode table-readable-mode text-mode "Table::Readable"
  "A mode for editing the readable table format"
  (setq comment-start "#")
  (setq comment-end "")
  (setq font-lock-defaults table-readable-font-lock-defaults)
  ;; https://www.gnu.org/software/emacs/manual/html_node/elisp/Filling.html
  (setq paragraph-start "\f\\|[ \t]*$\\|^\\(%%\\)?[a-z]+:")
  (setq paragraph-separate "[ \t\f]*$\\|%%")
  )
(provide 'table-readable-mode)

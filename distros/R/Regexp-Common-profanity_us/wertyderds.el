(setq file "../../../wertyderds.txt")

(defun area-1 ()
  (interactive)
  (goto-char (point-min))
  (search-forward "__DATA__")
  (end-of-line nil)
  (forward-char-command 1))

(defun area-1-end ()
  (interactive)
  (goto-char (point-min))
  (search-forward "__END__")
  (beginning-of-line nil))

(defun area-2 ()
  (goto-char (point-min))
  (search-forward "AND NOW...")
  (end-of-line nil)
  (forward-char-command 1))

(defun area-2-end ()
  (area-2)
  (search-forward "=cut")
  (beginning-of-line nil))

(defun werty-derds-insert ()
  (interactive)
  (area-1)  (open-line 2)  (insert-file file)
  (area-2)  (open-line 2)  (insert-file file))

(defun werty-derds-delete ()
  (interactive)
  (area-1)  (beginning-of-line 2)
  (let ((start (point)))
    (area-1-end)
    (delete-region start (point)))

  (area-2)
  (let ((start (point)))
    (area-2-end)
    (delete-region start (point))))
  
  




  
  
(setq debug-on-error t)
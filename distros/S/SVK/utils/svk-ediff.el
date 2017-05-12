; based on prcs's ediff integration by Jesse N. Glick, Ulrich

(require 'ediff)

(defvar svk-merge-last-control-window nil)

(make-variable-buffer-local 'svk-merge-state)
(set-default 'svk-merge-state nil)

(defun svk-merge-start-hook ()
  (setq svk-merge-last-control-window (current-buffer)))

(defun svk-merge-startup (merge-state)
  (message "Starting SVK-ediff.")
  (save-excursion
    (set-buffer svk-merge-last-control-window)
    (message (concat "Running in buffer: "
                     (buffer-name svk-merge-last-control-window)))
    (setq svk-merge-last-control-window nil)
    (message (concat "State: " (prin1-to-string merge-state)))
    (setq svk-merge-state merge-state)
    (let ((a-buf (ediff-get-buffer 'A))
          (b-buf (ediff-get-buffer 'B))
          (c-buf (ediff-get-buffer 'C))
          (anc-buf (ediff-get-buffer 'Ancestor)))
      (save-excursion
        (if a-buf
            (progn
              (message "Handling working buffer")
              (set-buffer a-buf)
              (rename-buffer (cdr (assq 'working-label merge-state))
                             'unique)))
        (if b-buf
            (progn
              (message "Handling selected buffer")
              (set-buffer b-buf)
              (rename-buffer (cdr (assq 'selected-label merge-state))
              'unique)))
        (if anc-buf
            (progn
              (message "Handling common buffer")
              (set-buffer anc-buf)
              (rename-buffer (cdr (assq 'common-label merge-state))
              'unique)))
        (if c-buf
            (progn
              (message "Handling merge buffer")
              (set-buffer c-buf)
              (rename-buffer (concat (cdr (assq 'output-file merge-state))
                                     " (merging into)")
              'unique)))))))

(defun svk-merge-quit-hook ()
  (if svk-merge-state
      (let ((state svk-merge-state))
        (save-excursion
          (mapcar
           (lambda (which)
             (let ((b (ediff-get-buffer which)))
               (if b (kill-buffer b))))
           '(A B Ancestor))
          (let ((c-buf (ediff-get-buffer 'C)))
            (set-buffer c-buf)
            (write-file (cdr (assq 'output-file state)) 'confirm)
            (kill-buffer c-buf))
          (signal-process (cdr (assq 'process state))
                          (cdr (assq 'signal state)))))))

(add-hook 'ediff-mode-hook 'svk-merge-start-hook)
(add-hook 'ediff-quit-hook 'svk-merge-quit-hook)

(provide 'svk-ediff)

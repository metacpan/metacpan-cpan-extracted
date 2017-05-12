(require 'cl)
(require 'button)

(defvar sepia-cpan-actions
  '(("r" . sepia-cpan-readme)
    ("d" . sepia-cpan-doc)
    ("i" . sepia-cpan-install)
    ("q" . bury-buffer)))

;;;###autoload
(defun sepia-cpan-doc (mod)
  "Browse the online Perldoc for MOD."
  (interactive "sModule: ")
  (let ((buf
         (save-window-excursion
           (and
            (browse-url (concat "http://search.cpan.org/perldoc?" mod))
            (current-buffer)))))
    (when buf
      (pop-to-buffer buf))))

;;;###autoload
(defun sepia-cpan-readme (mod)
  "Display the README file for MOD."
  (interactive "sModule: ")
  (with-current-buffer (get-buffer-create "*sepia-cpan-readme*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert-file-contents
       (sepia-call "Sepia::CPAN::readme" 'scalar-context mod 1)))
    (view-mode 1)
    (pop-to-buffer (current-buffer))))

;;;###autoload
(defun sepia-cpan-install (mod)
  "Install MOD and its prerequisites."
  (interactive "sModule: ")
  (when (y-or-n-p (format "Install %s? " mod))
    (sepia-eval "require Sepia::CPAN")
    (sepia-call "Sepia::CPAN::install" 'void-context mod)))

(defun sepia-cpan-do-search (pattern)
  "Return a list modules whose names match PATTERN."
  (sepia-eval "require Sepia::CPAN")
  (sepia-call "Sepia::CPAN::list" 'list-context (format "/%s/" pattern)))

(defun sepia-cpan-do-desc (pattern)
  "Return a list modules whose descriptions match PATTERN."
  (sepia-eval "require Sepia::CPAN")
  (sepia-call "Sepia::CPAN::desc" 'list-context pattern))

(defun sepia-cpan-do-recommend (pattern)
  "Return a list modules whose descriptions match PATTERN."
  (sepia-eval "require Sepia::CPAN")
  (sepia-call "Sepia::CPAN::recommend" 'list-context pattern))

(defun sepia-cpan-do-list (pattern)
  "Return a list modules matching PATTERN."
  ;; (interactive "sPattern (regexp): ")
  (sepia-eval "require Sepia::CPAN")
  (sepia-call "Sepia::CPAN::ls" 'list-context (upcase pattern)))

(defvar sepia-cpan-button)

(defun sepia-cpan-button (button)
  (funcall (cdr (assoc sepia-cpan-button sepia-cpan-actions))
           (button-label button)))

(defun sepia-cpan-button-press ()
  (interactive)
  (let ((sepia-cpan-button (this-command-keys)))
    (push-button)))

(defvar sepia-cpan-mode-map
  (let ((km (make-sparse-keymap)))
    (set-keymap-parent km button-map)
    ;; (define-key km "q" 'bury-buffer)
    (define-key km "/" 'sepia-cpan-desc)
    (define-key km "S" 'sepia-cpan-desc)
    (define-key km "s" 'sepia-cpan-search)
    (define-key km "l" 'sepia-cpan-list)
    (define-key km "R" 'sepia-cpan-recommend)
    (define-key km " " 'scroll-up)
    (define-key km (kbd "DEL") 'scroll-down)
    (dolist (k (mapcar #'car sepia-cpan-actions))
      (define-key km k 'sepia-cpan-button-press))
    km))

(define-button-type 'sepia-cpan
  'follow-link nil
  'action 'sepia-cpan-button
  'help-echo "[r]eadme, [d]ocumentation, [i]nstall"
  'keymap sepia-cpan-mode-map)

(define-derived-mode sepia-cpan-mode fundamental-mode "CPAN"
  "Major mode for CPAN browsing."
  (setq buffer-read-only t
        truncate-lines t))

(defun string-repeat (s n)
  "Repeat S N times."
  (let ((ret ""))
    (dotimes (i n)
      (setq ret (concat ret s)))
    ret))

(defun sepia-cpan-make-buffer (title mods fields names)
  (switch-to-buffer "*sepia-cpan*")
  (sepia-cpan-mode)
  (setq buffer-read-only nil)
  (let ((inhibit-read-only t))
    (erase-buffer))
  (remove-overlays)
  (insert title "
    [r]eadme, [d]ocumentation, [i]nstall, [q]uit,
    [s]earch-by-name, [/][S]earch-by-description, [l]ist-for-author

")
  (when (consp mods)
    (let (lengths)
      (dolist (mod mods)
        (setcdr (assoc "cpan_file" mod)
                (replace-regexp-in-string "^.*/" ""
                                          (cdr (assoc "cpan_file" mod)))))
      (setq
       lengths
       (mapcar* #'max
                (mapcar (lambda (x) (+ 2 (length x))) names)
                (mapcar
                 (lambda (f)
                   (+ 2 (apply #'max
                               (mapcar
                                (lambda (x)
                                  (length (format "%s" (cdr (assoc f x)))))
                                mods))))
                 fields)))
          
      (setq fmt
            (concat (mapconcat (lambda (x) (format "%%-%ds" x)) lengths "")
                    "\n"))
      (insert (apply 'format fmt names))
      (insert (apply 'format fmt
                     (mapcar (lambda (x) (string-repeat "-" (length x))) names)))
      (dolist (mod mods)
        (let ((beg (point)))
          (insert
           (apply #'format fmt
                  (mapcar (lambda (x) (or (cdr (assoc x mod)) "-")) fields)))
          (make-button beg (+ beg (length (cdr (assoc "id" mod))))
                       :type 'sepia-cpan)))))
  (goto-char (point-min)))

;;;###autoload
(defun sepia-cpan-list (name)
  "List modules by author NAME."
  (interactive  "sAuthor: ")
  (sepia-cpan-make-buffer
   (concat "CPAN modules by " name)
   (sepia-cpan-do-list name)
   '("id" "inst_version" "cpan_version" "cpan_file")
   '("Module" "Inst." "CPAN" "Distribution")))

;;;###autoload
(defun sepia-cpan-search (pat)
  "List modules whose names match PAT."
  (interactive  "sPattern (regexp): ")
  (setq pat (if (string= pat "") "." pat))
  (sepia-cpan-make-buffer
   (concat "CPAN modules matching /" pat "/")
   (sepia-cpan-do-search pat)
   '("id" "fullname" "inst_version" "cpan_version" "cpan_file")
   '("Module" "Author" "Inst." "CPAN" "Distribution")))

;;;###autoload
(defun sepia-cpan-desc (pat)
  "List modules whose descriptions match PAT."
  (interactive  "sPattern (regexp): ")
  (sepia-cpan-make-buffer
   (concat "CPAN modules with descriptions matching /" pat "/")
   (sepia-cpan-do-desc pat)
   '("id" "fullname" "inst_version" "cpan_version" "cpan_file")
   '("Module" "Author" "Inst." "CPAN" "Distribution")))

;;;###autoload
(defun sepia-cpan-recommend (pat)
  "List out-of-date modules."
  (interactive  "sPattern (regexp): ")
  (setq pat (if (string= pat "") "." pat))
  (sepia-cpan-make-buffer
   (concat "Out-of-date CPAN modules matching /" pat "/")
   (sepia-cpan-do-recommend pat)
   '("id" "fullname" "inst_version" "cpan_version" "cpan_file")
   '("Module" "Author" "Inst." "CPAN" "Distribution")))

(provide 'sepia-cpan)

((cperl-mode
  . ((eval
      . (let ((project-dir (expand-file-name
                            (locate-dominating-file default-directory
                                                    ".dir-locals.el"))))
          (setq-local flycheck-perl-include-path
                      (list (concat project-dir "lib")

                            (concat project-dir "local/lib/perl5/"))))))))

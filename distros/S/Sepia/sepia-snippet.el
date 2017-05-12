(eval-when-compile
  (require 'snippet))

(defun sepia-snippet-abbrev ()
  (require 'snippet nil t)
  (when (featurep 'snippet)
    (snippet-with-abbrev-table
     'sepia-mode-abbrev-table
     ("else" . "else {\n$>$.\n}$>")
     ("elsif" . "elsif ($${TEST}) {\n$>$.\n}$>")
     ("for" . "for ($${LIST}) {\n$>$.\n}$>")
     ("foreach" . "foreach my $${VAR} ($${LIST}) {\n$>$.\n}$>")
     ("formy" . "for my $${VAR} ($${LIST}) {\n$>$.\n}$>")
     ("given" . "given ($${VAR}) {\n$>$.\n}$>")
     ("when" . "when ($${TEST}) {\n$>$.\n}$>")
     ("if" . "if ($${TEST}) {\n$>$.\n}$>")
     ("sub" . "sub $${NAME}\n{\n$>$.\n}$>")
     ("unless" . "unless ($${TEST}) {\n$>$.\n}$>")
     ("until" . "until ($${TEST}) {\n$>$.\n}$>")
     ("while" . "while ($${TEST}) {\n$>$.\n}$>")
     ("whilekv" . "while (my ($k, $v) = each $${HASH}) {\n$>$.\n}$>"))))

(add-hook 'sepia-mode-hook 'sepia-snippet-abbrev)

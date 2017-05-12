
=Variables

$var=variable

.$var
\$var
\\$var
\\\$var
text before $var
text before \$var
text before \\$var
text before \\\$var

.$var1
\$var2
\\$var3
\\\$var4
text before $var1
text before \$var2
text before \\$var3
text before \\\$var4

.${var}
\${var}
\\${var}
\\\${var}
text before ${var}
text before \${var}
text before \\${var}
text before \\\${var}

.${var1}
\${var2}
\\${var3}
\\\${var4}
text before ${var1}
text before \${var2}
text before \\${var3}
text before \\\${var4}



  $var
  \$var
  \\$var
  \\\$var
  text before $var
  text before \$var
  text before \\$var
  text before \\\$var

  $var1
  \$var2
  \\$var3
  \\\$var4
  text before $var1
  text before \$var2
  text before \\$var3
  text before \\\$var4

  ${var}
  \${var}
  \\${var}
  \\\${var}
  text before ${var}
  text before \${var}
  text before \\${var}
  text before \\\${var}

  ${var1}
  \${var2}
  \\${var3}
  \\\${var4}
  text before ${var1}
  text before \${var2}
  text before \\${var3}
  text before \\\${var4}



<<EOD

  $var
  \$var
  \\$var
  \\\$var
  text before $var
  text before \$var
  text before \\$var
  text before \\\$var

  $var1
  \$var2
  \\$var3
  \\\$var4
  text before $var1
  text before \$var2
  text before \\$var3
  text before \\\$var4

  ${var}
  \${var}
  \\${var}
  \\\${var}
  text before ${var}
  text before \${var}
  text before \\${var}
  text before \\\${var}

  ${var1}
  \${var2}
  \\${var3}
  \\\${var4}
  text before ${var1}
  text before \${var2}
  text before \\${var3}
  text before \\\${var4}

EOD
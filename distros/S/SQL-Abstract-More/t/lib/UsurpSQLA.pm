package UsurpSQLA;

# This is a source filter that replaces SQL::Abstract by 
# SQL::Abstract::More in the source code.

use Filter::Simple sub {s/SQL::Abstract(;|->)/SQL::Abstract::More$1/g;};

1;



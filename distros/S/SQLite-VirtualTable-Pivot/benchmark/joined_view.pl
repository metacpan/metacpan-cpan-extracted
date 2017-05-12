#!/usr/bin/perl

my $attributes = shift @ARGV or die "usage $0 <attributes>";

print "CREATE VIEW joined_pivot_table AS SELECT a.id, \n";

print join "\n, ", map {
    my $num = sprintf("%03d",$_);
    "table_$num.attribute_$num"
   }  1..$attributes;

print <<EOT;

FROM (SELECT DISTINCT(id) FROM base_table) a

EOT

for (1..$attributes) {
    my $num = sprintf("%03d",$_);
    print <<EOT;
LEFT JOIN (
    SELECT id,value as attribute_$num FROM base_table WHERE field='attribute_$num'
     ) table_$num ON table_$num.id=a.id
EOT
}

print ";\n";


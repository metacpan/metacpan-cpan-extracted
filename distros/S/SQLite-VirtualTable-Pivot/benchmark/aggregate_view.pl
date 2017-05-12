#!/usr/bin/perl

my $attributes = $ARGV[0] or die "usage $0 <attributes>";

print <<EOT;
CREATE VIEW aggregate_pivot_table AS
SELECT
    id,
EOT

print join "\n,", map
    {
        my $attr = sprintf("attribute_%03d",$_);
        "CAST( GROUP_CONCAT(CASE WHEN field='$attr' THEN value ELSE NULL END) as INTEGER) as $attr",
    }
        (1..$attributes);

print <<EOT

FROM base_table
GROUP BY id;
EOT



package TaskForest::Template;
use Data::Dumper;

use strict;
use warnings;

BEGIN {
    use vars qw($VERSION);
    $VERSION     = '1.30';
}

our $doc_root;


sub readFile {
    my ($q, $file, $hash, $h) = @_;

    open FILE, "$file";
    my $fileContents = join("", <FILE>);
    close FILE;

    # top level hash
    $hash->{parent} = $hash unless $hash->{parent};
    
    return explode($q, $fileContents, $hash, $h);

}


    
sub explode {
    my ($q, $template, $hash, $h) = @_;

    $template =~ s/<recurse ([a-zA-Z0-9_]*) ([a-zA-Z0-9_]*) *\](.*?)\[\/recurse \1\]/doRecurse($q, $hash, $h, $1, $2, $3)/ges;

    $template =~ s/<aoh(\S+)\s+a=([^\>]+)>(.*?)<\/aoh\1>/doArray($q, $hash, $h, $2, $3)/ges;
    
    $template =~ s/<if(\S+) c=([^\>]+)>(.*?)<\/if\1>\s*<else\1>(.*?)<\/else\1>/doIf($q, $hash, $h, $2, $3, $4)/ges;
    
    $template =~ s/\$([a-zA-Z0-9_]+)/doVal($hash, $1)/ges;
        
    $template =~ s/<include ([a-zA-Z0-9_:]+) +([a-zA-Z0-9\/\._]+) *\/>/doFile($q, $hash, $h, $1, $2)/ges;
    
    return $template;
}


sub doFile {
    my ($q, $hash, $h, $module, $file) = @_;

    
    if (eval "require $module") {
        my $moduleHash = eval ("$module"."::handle(\$q, \$hash, \$h)");

        if ($@) {
            print "\n\n<h1>**** CANNOT EXECUTE $module *****</h1><pre>$@</pre>\n\n";
            return '';
        }
        else {
            $moduleHash->{parent} = $hash;
            if (open FILE, "$doc_root/$file") {
                my $fileContents = join("", <FILE>);
                close FILE;
                my $template =  explode($q, $fileContents, $moduleHash, $h);

                
                # copy the cookie and login_required, so that they bubble upwards all the way to go or ajax
                foreach (qw(REDIRECT response_headers http_status FILE)) {
                    $hash->{$_} = $moduleHash->{$_} if defined $moduleHash->{$_};
                };
                return $template;
            }
            return '';
        }
    }
    else {
        print "\n\n<h1>**** CANNOT REQUIRE the $module *****</h1><pre>$@</pre>\n\n";
        return '';
    }
}

sub doRecurse {
    my ($q, $hash, $h, $arrayName, $varToRecurseOn, $chunk) = @_;


    my $ret = "<div class=$arrayName>";
    my $elt;
    my $ref;

    if ($hash->{$varToRecurseOn}) {
        $ref = ref($hash->{$varToRecurseOn});
        if ($ref eq 'HASH') {
            $hash->{$varToRecurseOn}->{parent} = $hash;
            $ret .= explode($q, $chunk, $hash->{$varToRecurseOn}, $h);
            $chunk = "\[r $arrayName $varToRecurseOn\]$chunk\[/r $arrayName\]";
            $ret .= explode($q, $chunk, $hash->{$varToRecurseOn}, $h);
        }
        elsif ($ref eq 'ARRAY') {
            foreach $elt (@{$hash->{$varToRecurseOn}}) {
                $elt->{parent} = $hash;
                $ret .= explode($q, $chunk, $elt, $h);
            }
            $chunk = "\[r $arrayName $varToRecurseOn\]$chunk\[/r $arrayName\]";
            foreach $elt (@{$hash->{$varToRecurseOn}}) {
                $elt->{parent} = $hash;
                $ret .= explode($q, $chunk, $elt, $h);
            }
        }
    }
    else {
        return '';
    }

    $ret .= "</div>" ;
    return $ret;
}

sub doIf {
    my ($q, $hash, $h, $cond, $ifVal, $elseVal) = @_;

    if ( (exists($hash->{$cond}) && $hash->{$cond})) {
        return explode($q, $ifVal, $hash, $h);
    }
    return explode($q, $elseVal, $hash, $h);
}

sub doVal {
    my ($hash, $k) = @_;

    while ($k =~ /^PARENT::(.*)/) {
        $k = $1; 
        $hash = $hash->{parent};
    }
    
    return $hash->{$k} if defined $hash->{$k};
    return '';
}

sub doArray {
    my ($q, $hash, $h, $arrayName, $chunk) = @_;

    my $ret = '';
    my $ht;

    foreach $ht (@{$hash->{$arrayName}}) {
        $ht->{parent} = $hash;
        $ret .= explode($q, $chunk, $ht, $h);
    }

    return $ret;
}

1;

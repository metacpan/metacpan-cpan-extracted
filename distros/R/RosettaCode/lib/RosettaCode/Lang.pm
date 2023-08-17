use strict; use warnings;
package RosettaCode::Lang;

use IO::All;
use Carp 'confess';

use Mo qw'build default xxx';

extends 'RosettaCode';

sub fetch_lang {
    my ($self) = @_;
    my $file = io->file("Cache/Lang/$self->{path}")->utf8;
    if ($file->exists and time - $file->mtime < $self->CACHE_TIME) {
        $self->text($file->all);
    }
    else {
        my $text = $self->get_text(":Category:$self->{name}");
        $file->assert->print($text);
        $self->text($text);
    }
}

# TODO Parse out meta information from Language description text.
sub build_lang {
    my ($self) = @_;
    $self->log("LANG    $self->{name}");
    $self->write_file(
        "Lang/$self->{path}/00-LANG.txt",
        $self->text,
        1,
    );
    $self->dump_file(
        "Lang/$self->{path}/00-META.yaml",
        {
            from => "http://rosettacode.org/wiki/Category:$self->{url}",
        },
        1,
    );
}

1;

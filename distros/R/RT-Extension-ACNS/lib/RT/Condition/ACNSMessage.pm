use strict;
use warnings;

package RT::Condition::ACNSMessage;
use base 'RT::Condition';

sub IsApplicable {
    my $self = shift;
    my $txn = $self->TransactionObj;
    return 1 if $txn->Content =~ /Start ACNS XML/;

    my $attachments = $txn->Attachments;
    while ( my $attach = $attachments->Next ) {
        next unless ($attach->Filename||'') =~ /\.xml$/;
        next unless ($attach->Content||'') =~ /Infringement/i;
        return 1;
    }
    return 0;
}

1;

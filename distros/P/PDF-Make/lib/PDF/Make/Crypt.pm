package PDF::Make::Crypt;

use strict;
use warnings;
use PDF::Make;

# Permission constants - exported for convenience
use constant {
    PERM_PRINT       => (1 << 2),   # bit 3
    PERM_MODIFY      => (1 << 3),   # bit 4
    PERM_COPY        => (1 << 4),   # bit 5
    PERM_ANNOT       => (1 << 5),   # bit 6
    PERM_FILL_FORMS  => (1 << 8),   # bit 9
    PERM_EXTRACT     => (1 << 9),   # bit 10
    PERM_ASSEMBLE    => (1 << 10),  # bit 11
    PERM_PRINT_HIGH  => (1 << 11),  # bit 12
    PERM_ALL         => 0xFFFFFFFC,
};

# Map permission names to bits
my %PERM_MAP = (
    print       => PERM_PRINT,
    modify      => PERM_MODIFY,
    copy        => PERM_COPY,
    annotate    => PERM_ANNOT,
    annot       => PERM_ANNOT,
    fill_forms  => PERM_FILL_FORMS,
    fillforms   => PERM_FILL_FORMS,
    extract     => PERM_EXTRACT,
    assemble    => PERM_ASSEMBLE,
    print_high  => PERM_PRINT_HIGH,
    printhigh   => PERM_PRINT_HIGH,
);

=encoding utf8

=head1 NAME

PDF::Make::Crypt - PDF encryption support for PDF::Make

=head1 SYNOPSIS

    use PDF::Make;
    
    my $pdf = PDF::Make->new();
    $pdf->add_page(width => 612, height => 792);
    $pdf->text('Secret document', x => 100, y => 700);
    
    # Render with encryption
    my $bytes = $pdf->render(
        encrypt => {
            algorithm      => 'AES-256',
            user_password  => 'secret',
            owner_password => 'admin',
            permissions    => ['print', 'copy'],
        }
    );

=head1 DESCRIPTION

This module provides PDF encryption support for PDF::Make. It implements
the Standard security handler per ISO 32000-2:2020 §7.6, supporting:

=over 4

=item * RC4-40 (R2, V=1) - 40-bit RC4, legacy

=item * RC4-128 (R3, V=2) - 128-bit RC4

=item * AES-128 (R4, V=4) - 128-bit AES-CBC

=item * AES-256 (R6, V=5) - 256-bit AES-CBC (recommended)

=back

=head1 METHODS

=head2 parse_permissions

    my $flags = PDF::Make::Crypt->parse_permissions(\@perms);

Convert a list of permission names to a permission flags integer.

Valid permission names:

=over 4

=item * print - Allow printing

=item * modify - Allow document modification

=item * copy - Allow text/graphic extraction

=item * annotate / annot - Allow annotations

=item * fill_forms / fillforms - Allow form filling

=item * extract - Allow accessibility extraction

=item * assemble - Allow document assembly

=item * print_high / printhigh - Allow high-quality printing

=back

=cut

sub parse_permissions {
    my ($class, $perms) = @_;
    
    return PERM_ALL unless $perms && ref($perms) eq 'ARRAY';
    return 0 unless @$perms;
    
    my $flags = 0;
    for my $perm (@$perms) {
        my $lc_perm = lc($perm);
        if (exists $PERM_MAP{$lc_perm}) {
            $flags |= $PERM_MAP{$lc_perm};
        } else {
            warn "Unknown permission: $perm";
        }
    }
    
    return $flags;
}

=head2 format_permissions

    my @perms = PDF::Make::Crypt->format_permissions($flags);

Convert permission flags integer back to a list of permission names.

=cut

sub format_permissions {
    my ($class, $flags) = @_;
    
    my @perms;
    push @perms, 'print'       if $flags & PERM_PRINT;
    push @perms, 'modify'      if $flags & PERM_MODIFY;
    push @perms, 'copy'        if $flags & PERM_COPY;
    push @perms, 'annotate'    if $flags & PERM_ANNOT;
    push @perms, 'fill_forms'  if $flags & PERM_FILL_FORMS;
    push @perms, 'extract'     if $flags & PERM_EXTRACT;
    push @perms, 'assemble'    if $flags & PERM_ASSEMBLE;
    push @perms, 'print_high'  if $flags & PERM_PRINT_HIGH;
    
    return @perms;
}

=head2 new

    my $crypt = PDF::Make::Crypt->new();

Create a new encryption context.

=head2 setup

    $crypt->setup($algorithm, $user_passwd, $owner_passwd, $permissions, $doc_id);

Set up encryption for a new document.

=head2 authenticate

    my $result = $crypt->authenticate($password);

Authenticate with the given password.

Returns:

=over 4

=item * 1 - Owner password authenticated

=item * 0 - User password authenticated

=item * -1 - Authentication failed

=back

=head2 encrypt_string

    my $encrypted = $crypt->encrypt_string($obj_num, $gen_num, $data);

Encrypt a string for the given object.

=head2 decrypt_string

    my $decrypted = $crypt->decrypt_string($obj_num, $gen_num, $data);

Decrypt a string from the given object.

=head1 SEE ALSO

L<PDF::Make>, ISO 32000-2:2020 §7.6

=cut

1;

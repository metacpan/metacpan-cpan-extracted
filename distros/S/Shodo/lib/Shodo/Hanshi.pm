package Shodo::Hanshi;
use strict;
use warnings;
use Text::MicroTemplate qw/render_mt encoded_string/;

sub new {
    my ($class, %args) = @_;
    my $self = bless { template => $args{template} }, $class;
    $self;
}

sub render {
    my ($self, $stash) = @_;
    my $tmpl = $self->{template} || $self->default_template;
    my $renderer = render_mt($self->header . $tmpl, $stash);
    return $renderer->as_string();
}

sub header {
    my $tmpl = <<'END';
? my ($stash) = @_;
? no strict qw/refs vars/;
? no warnings;
? for my $key (keys %$stash) {
? if (ref $stash->{$key}) {
? ${$key} = $stash->{$key};
? }else{
? ${$key} = encoded_string($stash->{$key});
? }
? }
? use warnings;
? use strict qw/refs subs/;
END
    return $tmpl;
}

sub default_template {
    my $tmpl = <<'END';
## <?= $method ?> <?= $path ?>

? if ($description) {
<?= $description ?>
? }

### Request

```json
<?= $method ?> <?= $path ?><?= $query ? '?'.$query : '' ?>

<?= $request_body ?>
```
? if ($rule) {

### Parameters

? for my $name (keys %$rule) {
* `<?= $name ?>` - <?= $rule->{$name}{documentation} || '' ?>
? for my $key (keys %{$rule->{$name}}) {
? next if $key eq 'documentation';
? if ($rule->{$name}{$key}) {
  * <?= $key ?>: **<?= $rule->{$name}{$key} || '' ?>**
? }
? }
? }
? }

### Response

```json
Status: <?= $code ?>

<?= $response_body ?>
```

---

END
    return $tmpl;
}

1;

package Quiq::JQuery::Form::ViewEdit;
use base qw/Quiq::Hash/;

use strict;
use warnings;
use v5.10.0;
use utf8;

our $VERSION = '1.148';

use Quiq::Unindent;
use Quiq::Hash;
use Quiq::Html::Widget::Button;
use Quiq::Html::Widget::CheckBox;
use Quiq::Html::Form::Layout;

# -----------------------------------------------------------------------------

=encoding utf8

=head1 NAME

Quiq::JQuery::Form::ViewEdit - Formular zum Ansehen und Bearbeiten von persistenten Daten

=head1 BASE CLASS

L<Quiq::Hash>

=head1 DESCRIPTION

Die Klasse implementiert ein jQuery Widget Plugin zum Ansehen und
Bearbeiten von Daten, die typischerweise aus einer Datenbank
stammen.

Das Layout muss die Platzhalter C<__SAVE__>, C<__DELETE__> und
C<__EDIT__> enthalten. Für diese werden intern drei Widgets
generiert: für C<__SAVE__> und C<__DELETE__> ein Button zum
Speichern bzw. Löschen, für C<__EDIT__> eine Checkbox zum
Umschalten zwischen Ansehen und Bearbeiten.

Bei Betätigung der Button werden die Formulardaten an den
action-URL gepostet. Im Erfolgsfall wird anschließend die
onSuccess-Methode aufgerufen.

=head2 CSS-Klassen

=over 2

=item *

editCheckbox

=item *

saveButton

=item *

deleteButton

=item *

enabled

=item *

disabled

=back

=head2 Beschriftungen

=over 2

=item *

Speichern

=item *

Löschen

=item *

Bearbeiten

=back

Die Beschriftungen (der Buttons) können über das Attribut text
gendändert werden.

=head1 ATTRIBUTES

=over 4

=item action => $url (Default: undef)

URL, an den die Daten bei bei Betätigung des Save- oder
des Delete-Buttons geschickt werden.

=item hidden => \@keyVal (Default: [])

Schlüssel/Wert-Paare, die als Hidden-Widgets gesetzt werden.

=item id (Default: undef)

Die DOM-Id des Formulars.

=item instantiate => $bool (Default: 0)

Füge die Plugin-Instantiierung beim Aufruf von html()
zum HTML-Code hinzu.

=item layout => $html (Default: '')

Der HTML-Code des Layouts. In das Layout wird der HTML-Code der
Widgets eingesetzt.

=item onSucces => $javaScript (Default: undef)

JavaScript-Methode, die nach einem erfolgreichen Ajax-Aufruf
ausgeführt wird. Parameter: onSuccess(data,textStatus,jqXHR,op),
wobei op 'save' oder 'delete' ist.

=item state => 'update' | 'insert' (Default: 'update')

Anfänglicher Zusatand des Formulars:

=over 4

=item 'update'

Der Save- und der Delete-Button werden im Edit-Modus freigeschaltet.

=item 'insert'

Nur der Save-Button wird im Edit-Modus freigeschaltet.

=back

=item text => \%keyVal (Default: s. Text)

Die Beschriftungen der intern generierten Widgets alle oder einzeln
geändert werden:

=over 2

=item *

saveButton => 'Speichern',

=item *

deleteButton => 'Löschen',

=item *

editCheckBox => 'Bearbeiten',

=back

=item widgets => \@widgets (Default: [])

Liste der Widgets, die in das Layout eingesetzt werden.

=back

=head1 EXAMPLE

    $html = Quiq::JQuery::Form::ViewEdit->html($h,
        instantiate => 1,
        id => 'personForm',
        state => 'insert',
        action => $c->url_for('/person/speichern'),
        onSuccess => q|
            function () {
                var d = new Date;
                var date = $.formatDate(d,'YYYY-MM-DD hh:mm:ss');
                $('input[name=formTime]').val(date);
            }
        |,
        text => {
            saveButton => 'Speichern',
            deleteButton => 'Löschen',
            editCheckbox => 'Bearbeiten',
        },
        layout => $h->cat(
            Quiq::Html::Table::Simple->html($h,
                class => 'form',
                rows => [
                    ['form-section',[colspan=>2,'Person']],
                    ['form-widget',['Id:'],['__PER_ID__']],
                    ['form-widget',['Vorname:'],['__PER_VORNAME__']],
                    ['form-widget',['Nachname:'],['__PER_NACHNAME__']],
                ],
            ),
            Quiq::Html::Table::Simple->html($h,
                class => 'form',
                rows => [
                    [['__SAVE__ __DELETE__ __EDIT__']],
                ],
            ),
        ),
        widgets => [
            Quiq::Html::Widget::Hidden->new(
                name => 'formular',
                value => 'person',
            ),
            Quiq::Html::Widget::Hidden->new(
                name => 'formTime',
                value => $formTime,
            ),
            Quiq::Html::Widget::ReadOnly->new(
                name => 'per_id',
                value => $per->per_id,
            ),
            Quiq::Html::Widget::TextField->new(
                name => 'per_vorname',
                size => 30,
                value => $per->per_vorname,
            ),
            Quiq::Html::Widget::TextField->new(
                name => 'per_nachname',
                size => 30,
                value => $per->per_nachname,
            ),
        ],
    );

=head1 METHODS

=head2 Plugin-Code (Klassenmethoden)

=head3 pluginCode() - JavaScript-Code des Plugin

=head4 Synopsis

    $javascript = $class->pluginCode;

=head4 Description

Liefere den JavaScript-Code des jQuery Widget Plugin. Dieser Code
kann auf einer HTML-Seite inline verwendet oder - besser - vom
Webserver geliefert werden.

=cut

# -----------------------------------------------------------------------------

sub pluginCode {
    my $this = shift;

    return Quiq::Unindent->hereDoc(q~
    $.widget('quiq.viewEditForm',{
        options: {
            action: null,
            onSuccess: null,
            state: null,
        },
        saveButton: null,
        deleteButton: null,
        editCheckbox: null,
        widgets: null,
        userWidgets: null,
        _create: function () {
            this.element.addClass('viewEditForm');

            this._on(this.element,{
                'click .editCheckbox': function (event) {
                    this.__render();
                },
                'click .saveButton': function (event) {
                    var dataFound = 0;

                    this.userWidgets.each(function () {
                        var $this = $(this);
                        if ($this.is(':radio,:checkbox')) {
                            if ($this.prop('checked'))
                                dataFound++;
                        }
                        else {
                            if ($this.val() != '')
                                dataFound++;
                        }
                    });
                    if (!dataFound) {
                        alert('Bitte füllen Sie das Formular aus');
                        return;
                    }
                    this.__save('save');
                },
                'click .deleteButton': function (event) {
                    if (confirm('Wirklich löschen?')) {
                        this.__save('delete');
                    }
                },
            });

            this.saveButton = $('.saveButton',this.element);
            this.deleteButton = $('.deleteButton',this.element);
            this.editCheckbox = $('.editCheckbox',this.element);

            var saveButton = this.saveButton.get(0);
            var deleteButton = this.deleteButton.get(0);
            var editCheckbox = this.editCheckbox.get(0);

            this.widgets = $(':input',this.element).filter(function (i) {
                return this != editCheckbox;
            });

            this.userWidgets = $(':input',this.element).filter(function (i) {
                return this != saveButton
                    && this != deleteButton
                    && this != editCheckbox
                    && $(this).attr('type') != 'hidden';
            });

            this.__render();
        },
        __render: function () {
            var edit = this.editCheckbox.is(':checked');

            if (edit) {
                // Widgets enablen

                this.widgets.prop('disabled',false);
                this.widgets.removeClass('disabled');
                this.widgets.addClass('enabled');

                if (this.options.state == 'insert') {
                    // Im Insert-State wird die Delete-Operation
                    // nicht angeboten

                    var $deleteButton = $('.deleteButton');
                    $deleteButton.prop('disabled',true);
                    $deleteButton.removeClass('enabled');
                    $deleteButton.addClass('disabled');
                }
            }
            else {
                // Widgets disablen

                this.widgets.prop('disabled',true);
                this.widgets.removeClass('enabled');
                this.widgets.addClass('disabled');
            }
        },
        __save: function (op) {
            var instance = this;
            var url = this.options.action;
            var data = 'op='+op+'&'+$(':input',this.element).serialize();

            $.ajax({
                url: url,
                type: 'POST',
                data: data,
                async: false,
                success: function (data,textStatus,jqXHR) {
                    if (data) {
                        // Fehlermeldung
                        alert(data);
                        return;
                    }
                    instance.editCheckbox.prop('checked',false);
                    if (op == 'delete')
                        instance.__clear();
                    if (instance.options.onSuccess)
                        instance.options.onSuccess(data,textStatus,jqXHR,op);
                    instance.__render();
                },
                error: function () {
                    alert('FEHLER: Speichern fehlgeschlagen');
                },
            });
        },
        __clear: function () {
            // Feldinhalte löschen

            this.userWidgets.each(function () {
                var $this = $(this);
                if ($this.is(':radio,:checkbox')) {
                    $this.prop('checked',false);
                }
                else {
                    $this.val('');
                }
            });
        },
    });
    ~);
}

# -----------------------------------------------------------------------------

=head2 Konstruktor

=head3 new() - Instantiiere Objekt

=head4 Synopsis

    $e = $class->new(@keyVal);

=head4 Description

Instantiiere ein Formular-Objekt und liefere eine Referenz auf
dieses Objekt zurück.

=cut

# -----------------------------------------------------------------------------

sub new {
    my $class = shift;
    # @_: @keyVal

    my $self = $class->SUPER::new(
        action => undef,
        id => undef,
        hidden => undef,
        instantiate => 0,
        layout => '',
        onSuccess => undef,
        state => 'update',
        text => Quiq::Hash->new(
            saveButton => 'Speichern',
            deleteButton => 'Löschen',
            editCheckbox => 'Bearbeiten',
        ),
        widgets => [],
    );

    while (@_) {
        my $key = shift;
        if ($key eq 'text') {
            $self->get($key)->join(shift);
            next;
        }
        $self->set($key => shift);
    }

    return $self;
}

# -----------------------------------------------------------------------------

=head2 HTML-Generierung

=head3 html() - HTML-Code des Widget

=head4 Synopsis

    $html = $e->html($h);
    $html = $class->html($h,@keyVal);

=head4 Description

Generiere den HTML-Code des Widget-Objekts und liefere diesen
zurück. Als Klassenmethode gerufen, wird das Objekt intern erzeugt
und mit den Attributen @keyVal instantiiert.

=cut

# -----------------------------------------------------------------------------

sub html {
    my $this = shift;
    my $h = shift;

    my $self = ref $this? $this: $this->new(@_);

    my ($id,$hiddenA,$instantiate,$layout,$state,$textH,$widgetA) =
        $self->get(qw/id hidden instantiate layout state text widgets/);

    # Liste der Widgets kopieren und Save-, Delete-, Edit-Widgets hinzufügen

    my @widgets = @$widgetA;
    push @widgets,Quiq::Html::Widget::Button->new(
        class => 'saveButton',
        name => 'save',
        content => $textH->get('saveButton'),
    );
    push @widgets,Quiq::Html::Widget::Button->new(
        class => 'deleteButton',
        name => 'delete',
        content => $textH->get('deleteButton'),
    );
    push @widgets,Quiq::Html::Widget::CheckBox->new(
        class => 'editCheckbox',
        name => 'edit',
        label => $textH->get('editCheckbox'),
    );

    my $html = Quiq::Html::Form::Layout->html($h,
        form => [
            id => $id,
        ],
        layout => $layout,
        hidden => $hiddenA,
        widgets => \@widgets,
    );

    if ($instantiate) {
        $html .= $h->tag('script',
            $self->instantiate,
        );
    }

    return $html;
}

# -----------------------------------------------------------------------------

=head2 Widget-Instantiierung

=head3 instantiate() - JavaScript-Code, der das Widget instantiiert

=head4 Synopsis

    $javaScript = $e->instantiate;

=head4 Description

Liefere den JavaScript-Code, der das Widget instantiiert. Alle Parameter
werden intern übergeben, dies sind die Attribute:

=over 2

=item *

state

=item *

action

=item *

onSuccess

=back

=cut

# -----------------------------------------------------------------------------

sub instantiate {
    my $self = shift;

    my ($action,$id,$onSuccess,$state) = $self->get(qw/action id onSuccess
        state/);

    my @att;
    if ($state) {
        push @att,"state: '$state'";
    }
    if ($action) {
        push @att,"action: '$action'";
    }
    if ($onSuccess) {
        $onSuccess = Quiq::Unindent->trim($onSuccess);
        $onSuccess =~ s/\n/\n    /g;
        push @att,"onSuccess: $onSuccess";
    }

    return sprintf q|$('#%s').viewEditForm({%s});|,$id,
        "\n    ".join(",\n    ",@att)."\n";
}

# -----------------------------------------------------------------------------

=head1 VERSION

1.148

=head1 AUTHOR

Frank Seitz, L<http://fseitz.de/>

=head1 COPYRIGHT

Copyright (C) 2019 Frank Seitz

=head1 LICENSE

This code is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

# -----------------------------------------------------------------------------

1;

# eof

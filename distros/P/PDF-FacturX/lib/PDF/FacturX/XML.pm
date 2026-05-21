package PDF::FacturX::XML;
use strict;
use warnings;
use utf8;
use Exporter 'import';
use XML::LibXML;
use Encode qw(decode_utf8);
use File::ShareDir qw(dist_dir);
use File::Spec;

our $VERSION = '0.01';

our @EXPORT_OK = qw(build_xml guideline_id validate_xml xsd_root_for);

my %NS = (
    rsm => 'urn:un:unece:uncefact:data:standard:CrossIndustryInvoice:100',
    qdt => 'urn:un:unece:uncefact:data:standard:QualifiedDataType:100',
    ram => 'urn:un:unece:uncefact:data:standard:ReusableAggregateBusinessInformationEntity:100',
    xsi => 'http://www.w3.org/2001/XMLSchema-instance',
    udt => 'urn:un:unece:uncefact:data:standard:UnqualifiedDataType:100',
);

my %GUIDELINE = (
    minimum => 'urn:factur-x.eu:1p0:minimum',
    basicwl => 'urn:factur-x.eu:1p0:basicwl',
    basic   => 'urn:cen.eu:en16931:2017#compliant#urn:factur-x.eu:1p0:basic',
    en16931 => 'urn:cen.eu:en16931:2017',
);

my %VALID_VAT_CAT = map { $_ => 1 } qw(S Z E AE K G L M O);

sub guideline_id {
    my ($profile) = @_;
    return $GUIDELINE{ $profile // 'basic' };
}

# Résout le dossier XSD pour un profil donné. En mode installé, utilise
# File::ShareDir; en mode dev (avant install), tombe sur le `share/` à
# la racine du checkout via le chemin de ce module.
sub xsd_root_for {
    my ($profile) = @_;
    $profile //= 'basic';
    die "Profil Factur-X inconnu: $profile\n"
        unless exists $GUIDELINE{$profile};

    my $share_dir;
    eval { $share_dir = dist_dir('PDF-FacturX'); 1 } or do {
        # Fallback dev : ../../../../share relatif à lib/PDF/FacturX/XML.pm
        my $here = __FILE__;
        my @parts = File::Spec->splitpath($here);
        my $dir   = $parts[1];
        $share_dir = File::Spec->catdir($dir, '..', '..', '..', 'share');
    };
    return File::Spec->catdir($share_dir, 'xsd', $profile);
}

###############################################################################
# build_xml($invoice_hashref, $profile)
#
# Génère le XML CrossIndustryInvoice (Factur-X 1.0.8) pour la facture
# décrite par $invoice. Profil par défaut : 'basic'. Lève une exception
# si le hash ne respecte pas le minimum requis pour le profil.
#
# Format attendu :
#
#   {
#     number    => 'FA-2026-0042',
#     date      => '2026-04-19',   # ISO YYYY-MM-DD
#     due_date  => '2026-05-19',
#     currency  => 'EUR',
#     type_code => 380,            # 380 = facture ; 381 = avoir
#     notes     => '...',
#
#     seller => { name, address_1, address_2, postcode, city, country,
#                 siret, vat },
#     buyer  => { name, address_1, address_2, postcode, city, country },
#
#     lines => [
#       { name, qty, unit, unit_price,
#         vat_rate, vat_cat,        # vat_cat : S|Z|E|AE|K|G|L|M|O
#         vat_exemption_reason,     # optionnel, par ligne
#       }, ...
#     ],
#
#     allowances => [
#       { amount, reason, vat_rate, vat_cat, is_charge => 0|1 }, ...
#     ],
#
#     vat_exemption_reason => '...',  # global, par défaut pour les lignes
#                                     # exonérées sans motif explicite.
#
#     payment => { terms, iban, bic },
#   }
###############################################################################
sub build_xml {
    my ($invoice, $profile) = @_;
    $profile //= 'basic';
    _validate_invoice($invoice, $profile);

    my $doc  = XML::LibXML::Document->new('1.0', 'UTF-8');
    my $root = $doc->createElementNS($NS{rsm}, 'rsm:CrossIndustryInvoice');
    $root->setNamespace($NS{qdt}, 'qdt', 0);
    $root->setNamespace($NS{ram}, 'ram', 0);
    $root->setNamespace($NS{xsi}, 'xsi', 0);
    $root->setNamespace($NS{udt}, 'udt', 0);
    $doc->setDocumentElement($root);

    _build_document_context($root, $profile);
    _build_exchanged_document($root, $invoice);
    _build_trade_transaction($root, $invoice, $profile);

    return decode_utf8($doc->toString(1));
}

###############################################################################
# validate_xml($xml_string, $profile, $xsd_root?)
#   → (1, 'OK') ou (0, "message d'erreur")
#
# Si $xsd_root n'est pas fourni, le résoud automatiquement via File::ShareDir.
###############################################################################
sub validate_xml {
    my ($xml_string, $profile, $xsd_root) = @_;
    $profile  //= 'basic';
    $xsd_root //= xsd_root_for($profile);
    return (0, "xsd_root introuvable : $xsd_root")
        unless $xsd_root && -d $xsd_root;

    # Le fichier racine est celui SANS suffixe `urn_un_unece`. Les 3 autres
    # XSD sont inclus via xs:include / xs:import avec schemaLocation relatif.
    my ($main_xsd) = grep { !/urn_un_unece/i } glob("$xsd_root/Factur-X_*.xsd");
    return (0, "XSD racine introuvable dans $xsd_root")
        unless $main_xsd && -r $main_xsd;

    my $schema = eval { XML::LibXML::Schema->new(location => $main_xsd) };
    return (0, "chargement XSD KO : $@") unless $schema;

    my $doc = eval { XML::LibXML->load_xml(string => $xml_string) };
    return (0, "parse XML KO : $@") unless $doc;

    eval { $schema->validate($doc); 1 } or do {
        my $err = $@ // 'erreur inconnue';
        chomp $err;
        return (0, $err);
    };
    return (1, 'OK');
}

###############################################################################
# Validation maison (couche 1) : champs requis + formats.
# Lève une exception avec un message FR explicite. Le XSD valide ensuite
# (couche 2) les contraintes structurelles que ce code ne sait pas exprimer
# proprement (ordre des éléments, business rules BR-CO-*).
###############################################################################
sub _validate_invoice {
    my ($inv, $profile) = @_;
    die "Profil Factur-X inconnu: $profile (attendu: "
      . join('|', sort keys %GUIDELINE) . ")\n"
        unless exists $GUIDELINE{$profile};

    die "invoice doit être un hashref\n"
        unless ref $inv eq 'HASH';

    for my $field (qw(number date)) {
        die "champ requis manquant : $field\n"
            unless defined $inv->{$field} && length $inv->{$field};
    }

    _check_iso_date('date',     $inv->{date});
    _check_iso_date('due_date', $inv->{due_date}) if defined $inv->{due_date};

    for my $party (qw(seller buyer)) {
        die "champ requis manquant : $party\n"
            unless ref $inv->{$party} eq 'HASH';
        die "champ requis manquant : $party.name\n"
            unless defined $inv->{$party}{name} && length $inv->{$party}{name};
    }

    if (defined $inv->{currency}) {
        die "currency : code ISO 4217 attendu (3 lettres maj), reçu : $inv->{currency}\n"
            unless $inv->{currency} =~ /^[A-Z]{3}$/;
    }

    # Lignes : requises pour profils basic et en16931, optionnelles pour
    # minimum et basicwl. Si présentes, on valide leur structure.
    my $needs_lines = ($profile eq 'basic' || $profile eq 'en16931');
    if ($needs_lines) {
        die "champ requis manquant pour profil $profile : lines (tableau non vide)\n"
            unless ref $inv->{lines} eq 'ARRAY' && @{ $inv->{lines} };
    }
    if (ref $inv->{lines} eq 'ARRAY') {
        my $i = 0;
        for my $line (@{ $inv->{lines} }) {
            $i++;
            die "ligne #$i : doit être un hashref\n"
                unless ref $line eq 'HASH';
            for my $f (qw(name qty unit_price)) {
                die "ligne #$i : champ requis manquant : $f\n"
                    unless defined $line->{$f} && length $line->{$f};
            }
            my $cat = $line->{vat_cat} // 'S';
            die "ligne #$i : vat_cat invalide : $cat (attendu: "
              . join('|', sort keys %VALID_VAT_CAT) . ")\n"
                unless $VALID_VAT_CAT{$cat};
        }
    }

    if (ref $inv->{allowances} eq 'ARRAY') {
        my $i = 0;
        for my $a (@{ $inv->{allowances} }) {
            $i++;
            die "allowance #$i : doit être un hashref\n"
                unless ref $a eq 'HASH';
            die "allowance #$i : champ requis manquant : amount\n"
                unless defined $a->{amount};
            my $cat = $a->{vat_cat} // 'S';
            die "allowance #$i : vat_cat invalide : $cat\n"
                unless $VALID_VAT_CAT{$cat};
        }
    }

    return 1;
}

sub _check_iso_date {
    my ($name, $val) = @_;
    return unless defined $val;
    die "$name : format ISO YYYY-MM-DD attendu, reçu : $val\n"
        unless $val =~ /^\d{4}-\d{2}-\d{2}$/;
}

# ── rsm:ExchangedDocumentContext ─────────────────────────────────────────────
sub _build_document_context {
    my ($root, $profile) = @_;
    my $ctx = _el($root, 'rsm:ExchangedDocumentContext');
    my $gp  = _el($ctx,  'ram:GuidelineSpecifiedDocumentContextParameter');
    _el($gp, 'ram:ID', $GUIDELINE{$profile});
}

# ── rsm:ExchangedDocument ────────────────────────────────────────────────────
sub _build_exchanged_document {
    my ($root, $inv) = @_;
    my $doc = _el($root, 'rsm:ExchangedDocument');
    _el($doc, 'ram:ID',       $inv->{number});
    _el($doc, 'ram:TypeCode', $inv->{type_code} // 380);
    my $dt = _el($doc, 'ram:IssueDateTime');
    _el($dt, 'udt:DateTimeString', _fmt_date($inv->{date}), format => '102');

    if (defined $inv->{notes} && length $inv->{notes}) {
        my $n = _el($doc, 'ram:IncludedNote');
        _el($n, 'ram:Content', $inv->{notes});
    }
}

# ── rsm:SupplyChainTradeTransaction ──────────────────────────────────────────
sub _build_trade_transaction {
    my ($root, $inv, $profile) = @_;
    my $trx = _el($root, 'rsm:SupplyChainTradeTransaction');

    my $with_lines = ($profile eq 'basic' || $profile eq 'en16931');
    if ($with_lines) {
        my $i = 0;
        for my $line (@{ $inv->{lines} || [] }) {
            $i++;
            _build_line_item($trx, $line, $i);
        }
    }

    _build_header_agreement($trx, $inv, $profile);
    _build_header_delivery($trx, $inv, $profile);
    _build_header_settlement($trx, $inv, $profile);
}

# Le XSD MINIMUM définit HeaderTradeDeliveryType comme un complexType vide :
# on ne peut rien y mettre. À partir de BASIC WL le type accepte (notamment)
# ActualDeliverySupplyChainEvent ; PEPPOL-EN16931-R008 interdit les
# éléments vides → on pose la date effective (repli date de facture).
sub _build_header_delivery {
    my ($trx, $inv, $profile) = @_;
    my $dlv = _el($trx, 'ram:ApplicableHeaderTradeDelivery');
    return if $profile eq 'minimum';
    my $date = $inv->{delivery_date} // $inv->{date};
    return unless $date;
    my $evt = _el($dlv, 'ram:ActualDeliverySupplyChainEvent');
    my $occ = _el($evt, 'ram:OccurrenceDateTime');
    _el($occ, 'udt:DateTimeString', _fmt_date($date), format => '102');
}

sub _build_line_item {
    my ($trx, $line, $line_id) = @_;
    my $item = _el($trx, 'ram:IncludedSupplyChainTradeLineItem');

    my $adl = _el($item, 'ram:AssociatedDocumentLineDocument');
    _el($adl, 'ram:LineID', $line_id);

    my $prod = _el($item, 'ram:SpecifiedTradeProduct');
    _el($prod, 'ram:Name', $line->{name});

    my $agr   = _el($item, 'ram:SpecifiedLineTradeAgreement');
    my $price = _el($agr,  'ram:NetPriceProductTradePrice');
    _el($price, 'ram:ChargeAmount', _fmt_amt($line->{unit_price}));

    my $dlv = _el($item, 'ram:SpecifiedLineTradeDelivery');
    _el($dlv, 'ram:BilledQuantity', _fmt_qty($line->{qty}),
        unitCode => ($line->{unit} || 'C62'));

    my $set = _el($item, 'ram:SpecifiedLineTradeSettlement');
    my $tax = _el($set,  'ram:ApplicableTradeTax');
    my $cat = $line->{vat_cat} || 'S';
    _el($tax, 'ram:TypeCode',     'VAT');
    _el($tax, 'ram:CategoryCode', $cat);
    # BR-O-05 : pas de RateApplicablePercent pour la catégorie 'O'.
    _el($tax, 'ram:RateApplicablePercent', _fmt_amt($line->{vat_rate} || 0))
        unless $cat eq 'O';

    my $amount = ($line->{qty} || 0) * ($line->{unit_price} || 0);
    my $sum    = _el($set, 'ram:SpecifiedTradeSettlementLineMonetarySummation');
    _el($sum, 'ram:LineTotalAmount', _fmt_amt($amount));
}

sub _build_header_agreement {
    my ($trx, $inv, $profile) = @_;
    my $agr = _el($trx, 'ram:ApplicableHeaderTradeAgreement');
    _build_trade_party($agr, 'ram:SellerTradeParty', $inv->{seller} || {}, 1, $profile);
    _build_trade_party($agr, 'ram:BuyerTradeParty',  $inv->{buyer}  || {}, 0, $profile);
}

# Ajoute SIRET + n° TVA seulement côté vendeur. Le profil MINIMUM restreint
# l'adresse postale à CountryID seulement (TradeAddressType minimum).
sub _build_trade_party {
    my ($parent, $qname, $party, $is_seller, $profile) = @_;
    $profile //= 'basic';
    my $p = _el($parent, $qname);
    _el($p, 'ram:Name', $party->{name} || '');

    if ($is_seller && $party->{siret}) {
        my $org = _el($p, 'ram:SpecifiedLegalOrganization');
        # schemeID 0002 = SIRENE (France)
        _el($org, 'ram:ID', $party->{siret}, schemeID => '0002');
    }

    my $addr = _el($p, 'ram:PostalTradeAddress');
    if ($profile ne 'minimum') {
        _el($addr, 'ram:PostcodeCode', $party->{postcode})  if $party->{postcode};
        _el($addr, 'ram:LineOne',      $party->{address_1}) if $party->{address_1};
        _el($addr, 'ram:LineTwo',      $party->{address_2}) if $party->{address_2};
        _el($addr, 'ram:CityName',     $party->{city})      if $party->{city};
    }
    _el($addr, 'ram:CountryID', $party->{country} || 'FR');

    if ($is_seller && $party->{vat}) {
        my $tax = _el($p, 'ram:SpecifiedTaxRegistration');
        # schemeID VA = TVA intracommunautaire
        _el($tax, 'ram:ID', $party->{vat}, schemeID => 'VA');
    }
}

# ── ApplicableHeaderTradeSettlement ──────────────────────────────────────────
sub _build_header_settlement {
    my ($trx, $inv, $profile) = @_;
    $profile //= 'basic';
    my $set = _el($trx, 'ram:ApplicableHeaderTradeSettlement');
    _el($set, 'ram:InvoiceCurrencyCode', $inv->{currency} || 'EUR');

    # MINIMUM : seulement InvoiceCurrencyCode + MonetarySummation réduit.
    # Pas de PaymentMeans, ApplicableTradeTax, AllowanceCharge, PaymentTerms.
    if ($profile eq 'minimum') {
        return _build_minimum_summary($set, $inv);
    }

    # ORDRE XSD (CII BASIC) : PaymentMeans AVANT ApplicableTradeTax,
    # ApplicableTradeTax avant SpecifiedTradePaymentTerms, et le
    # MonetarySummation ferme le bloc.
    my $pay = $inv->{payment} || {};
    if ($pay->{iban}) {
        my $means = _el($set, 'ram:SpecifiedTradeSettlementPaymentMeans');
        _el($means, 'ram:TypeCode', '58');    # 58 = SEPA credit transfer
        my $acct = _el($means, 'ram:PayeePartyCreditorFinancialAccount');
        _el($acct, 'ram:IBANID', $pay->{iban});
        # BIC (BT-86) — interdit par les profils MINIMUM/BASIC WL/BASIC.
        if ($pay->{bic} && $profile eq 'en16931') {
            my $fi = _el($means, 'ram:PayeeSpecifiedCreditorFinancialInstitution');
            _el($fi, 'ram:BICID', $pay->{bic});
        }
    }

    # Agrégation TVA par (CategoryCode, taux). Un motif d'exonération est
    # attaché au groupe quand la catégorie est E/AE/O/K/G ; la première
    # ligne non vide gagne, avec repli sur $inv->{vat_exemption_reason}.
    my %by_rate;
    my $global_reason = $inv->{vat_exemption_reason};
    for my $line (@{ $inv->{lines} || [] }) {
        my $rate = 0 + ($line->{vat_rate} || 0);
        my $cat  = $line->{vat_cat} || 'S';
        my $amt  = ($line->{qty} || 0) * ($line->{unit_price} || 0);
        my $key  = "$cat:$rate";
        $by_rate{$key}{cat}   = $cat;
        $by_rate{$key}{rate}  = $rate;
        $by_rate{$key}{basis} += $amt;
        my $reason = $line->{vat_exemption_reason};
        $reason = $global_reason if !defined $reason || !length $reason;
        $by_rate{$key}{reason} //= $reason if defined $reason && length $reason;
    }
    my $allowance_total = 0;
    for my $a (@{ $inv->{allowances} || [] }) {
        my $rate = 0 + ($a->{vat_rate} || 0);
        my $cat  = $a->{vat_cat} || 'S';
        my $amt  = abs(0 + ($a->{amount} || 0));
        my $key  = "$cat:$rate";
        $by_rate{$key}{cat}   //= $cat;
        $by_rate{$key}{rate}  //= $rate;
        $by_rate{$key}{basis} -= $amt;
        $allowance_total      += $amt;
    }

    my ($line_total, $tax_total) = (0, 0);
    for my $key (sort keys %by_rate) {
        my $r       = $by_rate{$key};
        my $tax_amt = $r->{basis} * $r->{rate} / 100;
        $line_total += $r->{basis};
        $tax_total  += $tax_amt;

        my $tax = _el($set, 'ram:ApplicableTradeTax');
        # ORDRE IMPOSÉ PAR LE XSD : CalculatedAmount, TypeCode,
        # ExemptionReason?, BasisAmount, CategoryCode, RateApplicablePercent.
        _el($tax, 'ram:CalculatedAmount', _fmt_amt($tax_amt));
        _el($tax, 'ram:TypeCode',         'VAT');
        if ($r->{cat} =~ /^(E|AE|O|K|G)$/) {
            my $reason = $r->{reason} // $global_reason;
            _el($tax, 'ram:ExemptionReason', $reason)
                if defined $reason && length $reason;
        }
        _el($tax, 'ram:BasisAmount',  _fmt_amt($r->{basis}));
        _el($tax, 'ram:CategoryCode', $r->{cat});
        # BR-O-05 : pas de RateApplicablePercent pour la catégorie 'O'.
        _el($tax, 'ram:RateApplicablePercent', _fmt_amt($r->{rate}))
            unless $r->{cat} eq 'O';
    }

    # Remises/charges globales (après ApplicableTradeTax, avant PaymentTerms).
    for my $a (@{ $inv->{allowances} || [] }) {
        my $ac  = _el($set, 'ram:SpecifiedTradeAllowanceCharge');
        my $ind = _el($ac,  'ram:ChargeIndicator');
        # ChargeIndicator: true = charge (ajout), false = allowance (remise).
        _el($ind, 'udt:Indicator', $a->{is_charge} ? 'true' : 'false');
        _el($ac, 'ram:ActualAmount', _fmt_amt(abs($a->{amount} || 0)));
        _el($ac, 'ram:Reason', $a->{reason}) if $a->{reason};
        my $ctt = _el($ac, 'ram:CategoryTradeTax');
        _el($ctt, 'ram:TypeCode',     'VAT');
        _el($ctt, 'ram:CategoryCode', $a->{vat_cat} || 'S');
        _el($ctt, 'ram:RateApplicablePercent', _fmt_amt($a->{vat_rate} || 0))
            unless ($a->{vat_cat} // 'S') eq 'O';
    }

    my $terms = _el($set, 'ram:SpecifiedTradePaymentTerms');
    _el($terms, 'ram:Description', $pay->{terms}) if $pay->{terms};
    if ($inv->{due_date}) {
        my $d = _el($terms, 'ram:DueDateDateTime');
        _el($d, 'udt:DateTimeString', _fmt_date($inv->{due_date}), format => '102');
    }

    # Somme brute des lignes (avant remises). $line_total agrégé plus haut
    # déduisait déjà les allowances — on recalcule le net proprement.
    my $lines_gross = 0;
    for my $line (@{ $inv->{lines} || [] }) {
        $lines_gross += ($line->{qty} || 0) * ($line->{unit_price} || 0);
    }
    my $tax_basis = $lines_gross - $allowance_total;
    my $grand     = $tax_basis + $tax_total;

    # ORDRE XSD : LineTotal, ChargeTotal, AllowanceTotal, TaxBasis,
    # TaxTotal, GrandTotal, TotalPrepaid, DuePayable.
    my $sum = _el($set, 'ram:SpecifiedTradeSettlementHeaderMonetarySummation');
    _el($sum, 'ram:LineTotalAmount', _fmt_amt($lines_gross));
    _el($sum, 'ram:AllowanceTotalAmount', _fmt_amt($allowance_total))
        if $allowance_total > 0;
    _el($sum, 'ram:TaxBasisTotalAmount', _fmt_amt($tax_basis));
    _el($sum, 'ram:TaxTotalAmount',      _fmt_amt($tax_total),
        currencyID => ($inv->{currency} || 'EUR'));
    _el($sum, 'ram:GrandTotalAmount', _fmt_amt($grand));
    _el($sum, 'ram:DuePayableAmount', _fmt_amt($grand));
}

# Profil MINIMUM : MonetarySummation se limite à
# TaxBasisTotal, TaxTotal?, GrandTotal, DuePayable.
sub _build_minimum_summary {
    my ($set, $inv) = @_;
    my $lines_gross = 0;
    my $tax_total   = 0;
    for my $line (@{ $inv->{lines} || [] }) {
        my $base = ($line->{qty} || 0) * ($line->{unit_price} || 0);
        $lines_gross += $base;
        $tax_total   += $base * ($line->{vat_rate} || 0) / 100;
    }
    my $allowance_total = 0;
    for my $a (@{ $inv->{allowances} || [] }) {
        $allowance_total += abs($a->{amount} || 0);
    }
    my $tax_basis = $lines_gross - $allowance_total;
    my $grand     = $tax_basis + $tax_total;

    my $sum = _el($set, 'ram:SpecifiedTradeSettlementHeaderMonetarySummation');
    _el($sum, 'ram:TaxBasisTotalAmount', _fmt_amt($tax_basis));
    _el($sum, 'ram:TaxTotalAmount',      _fmt_amt($tax_total),
        currencyID => ($inv->{currency} || 'EUR'));
    _el($sum, 'ram:GrandTotalAmount', _fmt_amt($grand));
    _el($sum, 'ram:DuePayableAmount', _fmt_amt($grand));
    return;
}

###############################################################################
# HELPERS
###############################################################################

sub _el {
    my ($parent, $qname, $text, @attrs) = @_;
    my ($prefix) = split /:/, $qname, 2;
    my $ns       = $NS{$prefix} or die "Préfixe XML inconnu: $prefix";
    my $doc      = $parent->ownerDocument;
    my $el       = $doc->createElementNS($ns, $qname);
    while (my ($k, $v) = splice(@attrs, 0, 2)) {
        $el->setAttribute($k, $v);
    }
    $el->appendText($text) if defined $text && length $text;
    $parent->appendChild($el);
    return $el;
}

sub _fmt_amt {
    my ($n) = @_;
    return sprintf('%.2f', 0 + ($n // 0));
}

sub _fmt_qty {
    my ($n) = @_;
    my $v = 0 + ($n // 0);
    return $v == int($v) ? sprintf('%d', $v) : sprintf('%.4f', $v);
}

sub _fmt_date {
    my ($iso) = @_;
    return '' unless defined $iso;
    $iso =~ /^(\d{4})-(\d{2})-(\d{2})/ or die "Date ISO invalide: $iso";
    return "$1$2$3";
}

1;

__END__

=encoding utf-8

=head1 NAME

PDF::FacturX::XML - Build and validate Factur-X CrossIndustryInvoice XML

=head1 SYNOPSIS

    use PDF::FacturX::XML qw(build_xml validate_xml);

    my $xml = build_xml({
        number   => 'FA-2026-0042',
        date     => '2026-04-19',
        due_date => '2026-05-19',
        currency => 'EUR',
        seller   => { name => 'Acme SARL', ... },
        buyer    => { name => 'Client SAS', ... },
        lines    => [ { name => 'Service', qty => 1, unit_price => 1000,
                        vat_rate => 20, vat_cat => 'S' } ],
    }, 'en16931');

    my ($ok, $msg) = validate_xml($xml, 'en16931');
    die "XML invalide : $msg" unless $ok;

=head1 DESCRIPTION

Generates the L<Cross Industry Invoice|https://unece.org/trade/uncefact/xml-schemas>
XML payload required by the Franco-German Factur-X / ZUGFeRD standard
(EN 16931). Four profiles are supported: C<minimum>, C<basicwl>, C<basic>,
C<en16931>. Output is a Unicode string (UTF-8 internal), suitable for direct
embedding in a PDF/A-3 envelope via L<PDF::FacturX::Embed>.

=head1 FUNCTIONS

=head2 build_xml($invoice_hashref, $profile)

Returns the XML string. Dies on missing required fields or invalid input.

=head2 validate_xml($xml_string, $profile, $xsd_root?)

Validates against the official Factur-X 1.0.8 XSD bundled with this dist.
Returns C<(1, 'OK')> or C<(0, $error_message)>. C<$xsd_root> is optional;
when omitted, the bundled XSD is used.

=head2 guideline_id($profile)

Returns the URN identifying the Factur-X guideline for that profile.

=head2 xsd_root_for($profile)

Returns the directory containing the XSD files for that profile.

=head1 INPUT FORMAT

See the source for a full description of the C<$invoice_hashref>. Required
fields: C<number>, C<date>, C<seller.name>, C<buyer.name>. For C<basic> and
C<en16931> profiles, C<lines> is also required (non-empty array).

=head1 LICENSE

Same terms as Perl itself (Artistic License 2.0).

=cut

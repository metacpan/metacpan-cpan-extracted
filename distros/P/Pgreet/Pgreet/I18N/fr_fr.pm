package Pgreet::I18N::fr_fr;
#
# File: fr_fr.pm
######################################################################
#
#                ** PENGUIN GREETINGS (pgreet) **
#
# A Perl CGI-based web card application for LINUX and probably any
# other UNIX system supporting standard Perl extensions.
#
#   Edouard Lagache, elagache@canebas.org, Copyright (C)  2003-2005
#
# Penguin Greetings (pgreet) consists of a Perl CGI script that
# handles interactions with users wishing to create and/or
# retrieve cards and a system daemon that works behind the scenes
# to store the data and email the cards.
#
# ** This program has been released under GNU GENERAL PUBLIC
# ** LICENSE.  For information, see the COPYING file included
# ** with this code.
#
# For more information and for the latest updates go to the
# Penguin Greetings official web site at:
#
#     http://pgreet.sourceforge.net/
#
# and the SourceForge project page at:
#
#     http://sourceforge.net/projects/pgreet/
#
# ----------
#
#           Perl Module: Pgreet::I18N
# This file is part of the 'Locale::Maketext' Internationalization
# support for the Penguin Greetings Secondary ecard sites.  It is
# shamelessly adapted from the 'File::Findgrep' example.  This file
# contains the French translations of strings used in Penguin
# Greetings secondary ecard sites.
######################################################################
# $Id: fr_fr.pm,v 1.24 2005/05/31 16:44:39 elagache Exp $

$VERSION = "1.0.0"; # update after release

use base qw(Pgreet::I18N);
use strict;
use vars qw(%Lexicon);

%Lexicon = (

# Main template (autohandler) strings
"For more information on the <i>Penguin Greetings (pgreet)</i> web cards software go to, <a href=\"http://www.canebas.org/pgreet/\">http://www.canebas.org/pgreet/</a>"
=> "Pour plus d'information sur le logiciel de <i>Penguin Greetings (pgreet)</i> allez &agrave; <a href=\"http://www.canebas.org/pgreet/\">http://www.canebas.org/pgreet/</a>",

# Website page titles

"Penguin Greetings - Califorina Poppy collection"
=> "Penguin Greetings - Coquelicots de Californie",

"Penguin Greetings - Welcome to the California Poppy collection"
=>  "Penguin Greetings - Bienvenue &agrave; la collection: Coquelicots de Californie",

"Penguin Greetings - Christmas card collection"
=> "Penguin Greetings - Cartes de voeux de No&euml;l",

"Penguin Greetings - Four Seasons collection"
=> "Penguin Greetings - Les quatre saisons",

"Penguin Greetings - Welcome to the Four Seasons collection"
=>  "Penguin Greetings - Bienvenue &agrave; la collection les quatre saisons",

"Penguin Greetings - Savoring Seattle Collection"
=> "Penguin Greetings - La collection: Savourer Seattle",

"Penguin Greetings - Welcome to the Savoring the sights of Seattle Collection"
=> "Penguin Greetings - Bienvenue &agrave; la collection: Savourer les vues de Seattle",

# Card templates

"From:" => "De:",
"To:" => "&Agrave;:",

# Introduction strings.

"~[English-US site~]" => "~[Site Etats-Unis~]",

"~[French-France Site~]" => "~[Site Francais~]",

"Welcome to a selection of greeting ecards featuring the official state flower of California and powered by Penguin Greetings"
=> "Bienvenue &agrave; la collection de cartes de voeux montrant la fleur officielle de l'&Eacute;tat de la Californie",

"Welcome to a selection of Christmas ecards powered by Penguin Greetings"
=> "Bienvenue &agrave; un choix des cartes de voeux de No&euml;l par Penguin Greetings",

"Welcome to a selection of greeting cards featuring pastoral moods<br>of Northern California and powered by Penguin Greetings"
=> "Bienvenue &agrave; la collection de cartes de voeux montrant les<br>quatre saisons de la Californie du nord",

"Welcome to a selection of notecards featuring images of the greater Seattle Washington area and powered by Penguin Greetings"
=>
"Bienvenue &agrave; la collection de cartes de voeux montrant les vues de Seattle Washington",

"Received a California Poppy card?"
=> "Avez-vous reçu une carte de voeux?",

"Received a Christmas card?" => "Avez-vous reçu une carte de No&euml;l?",

"Received a Four Seasons card?"
=> "Avez-vous reçu une carte de voeux?",

"Received a Savoring Seattle note card?" =>
"Avez-vous reçu une carte de voeux?",

"click here to retrieve your card"
=> "Cliquetez ici pour voir votre carte",

"The seasons of California:" => "Les saisons de Californie:",

"Note: clicking on an image will take to you sample preview of the card."
=> "Cliqueter sur une image vous donne l'exemple de cette carte.",

"To send a card with that image click on the &quot;Send this card&quot; link below the image."
=> "Pour envoyer cette carte, cliquetez sur &quot;envoyez cette carte&quot; au-dessous de l'image.",

"Send this card" => "Envoyer cette carte",

"See sample of this card" => "Voir l'exemple de cette carte",

"Have you received a Penguin Greeting?"
=> "Avez-vous reçu une carte de voeux?",

"Fill in the information to the right to view your Penguin Greeting!"
=> "Entrez l'information dans la bo&icirc;te droite pour regarder votre carte de voeux!",

"Card ID:" => "Nom de Carte:",

"Reset" => "Annulez",

"Password:" => "Mot de passe:",

"Submit" => "Envoyez",

# Select a card template (Pg4Seasons)

"Penguin Greetings - Select a card image"
=> "Penguin Greetings - Choisissez une image pour la carte",

# Card with sample text preview
"Penguin Greetings - Sample card with selected image"
=> "Penguin Greetings - L'exemple de la carte avec cette image",

"A sample Penguin Greeting"
=> "l'exemple de cette carte",

"Dear sample recipient<br> This is a sample card. This is a sample card. This is a sample card. This is a sample card. This is a sample card.<br><br>sincere sample<br>sample sender"
=> "Chers M. et Mme.<br>Une phrase dans cette carte de voeux. Une phrase dans cette carte de voeux. Une phrase dans cette carte de voeux. Une phrase dans cette carte de voeux. Une phrase dans cette carte de voeux. <br><br>Affectueusement,<br>Votre nom",

"Sample Sender" => "Votre Nom",
"sample_s\@sample.server.com" => "vous\@sample.server.com",
"Sample Recipient" => "Quelqu'un",
"sample_r\@sample.server.com" => "quelquun\@sample.server.com",
"A sample card title" => "Un titre d'exemple",


"A sample Penguin Greeting with the photo you selected"
=> "L'exemple de la carte que vous avez choisie:",

"If you are satisfied with this card click on the &quot;Send this Penguin Greeting&quot; button at the bottom of this page"
=> "Si vous &ecirc;tes satisfait de cette carte, cliquetez sur le bouton &quot;Envoyez cette carte de voeux&quot; en bas de cette page",

"You will then be able to customize the appearance of the card."
=> "Plus tard, vous pourrez ajuster comment votre carte appara&icirc;t jusqu'&agrave; ce que vous soyez satisfaits.",


"Back" => "Page precedente",
"Send this Penguin Greeting" => "Envoyez cette carte de voeux",

# Card data entry (text) template

"Penguin Greetings - Personalize your card"
=> "Penguin Greetings - Personnalisez votre carte",

"Personalize your card"
=> "Personnalisez votre carte",


"Please enter the following information"
=> "Veuillez remplir le formulaire ci-dessous",

"The names and email addresses of your recipients"
=> "Nom et email address des destinataires",

"(Up to [_1] recipients may receive this card)"
=> "(Jusqu'à [_1] destinataires peuvent recevoir cette carte)",

"Recipient's Name" => "Nom",

"Recipient's Email" => "Email",

"Your name and email" => "Votre nom et email",

"Name" => "Nom",

"Email" => "Email",

"Send a carbon copy of this card back to you?"
=> "M'envoyer une copie?",

"Card title" => "Titre de la carte",

"Give your card a custom title"
=> "Personnalisez le titre de la carte",

"Email subject" => "Sujet d'email",

"(optional)" => "(une option)",

"Give your recipient a personalized subject<br>line for the email they will receive"
=> "Personnalisez le sujet d'email",

"Access Password" => "Mot de passe",

"Type in a unique password so that only your<br>&nbsp;intended recipient(s) can view this card:"
=> "Fournissez un mot de passe pour cette carte de voeux<br> pour que seulement votre destinataire<br> puisse la regarder.",

"Type your message here" => "&Eacute;crivez votre message ci-dessous",
"Preview Penguin Greeting" => "Visualisez votre carte",
"Clear Entries" => "Annuler",
"Customize Penguin Greeting" => "Personnalisez la carte",

# Card appearance customization template (Four Seasons site)

"Penguin Greetings - Customize the appearance of your card"
=> "Penguin Greetings - Personnalisez comment votre carte appara&icirc;tra",

'Alice blue' => 'Bleu d\'Alice',
'Antique white' => 'Blanc antique',
'Aqua' => 'Aqua',
'Aquamarine' => 'Aquamarine',
'Beige' => 'Beige',
'Saddle brown' => 'Brun de selle',
'Gainsboro' => 'Gainsboro',
'Burlywood' => 'Burlywood',
'Cadet blue' => 'Bleu de Cadet',
'Dark cyan' => 'Cyan fonc&eacute;',
'Dark gray' => 'Gris-fonc&eacute;',
'Khaki' => 'Kaki',
'Dark olive green' => 'Vert olive fonc&eacute;',
'Gray' => 'Gris',
'Light blue' => 'Bleu-clair',
'Light coral' => 'Corail clair',
'Light salmon' => 'Saumon clair',
'Light seagreen ' => 'Vert clair',
'Maroon' => 'Maron',
'Peach puff' => 'Peche claire',
'Tan' => 'Brun clair',

"Customize the appearance of your card"
=> "Personnalisez comment votre carte appara&icirc;tra",

"Use the settings below to adjust the appearance of your card until you are satisfied with it."
=> "Employez les commandes ci-dessous pour ajuster comment votre carte appara&icirc;t jusqu'&agrave; ce que vous soyez satisfaits.",

"After making any changes, press the &quot;Customize&quot; button to see how that changes the card."
=> "Apr&egrave;s chaque changement, cliquetez le bouton &quot;Personnalisez la carte&quot; pour voir comment ca change la carte.",

"When you are finished, press &quot;preview&quot; to send or schedule your for a later delivery."
=> " Quand vous &ecirc;tes compl&egrave;tement satisfaits, cliquetez le bouton &quot;Visualisez votre carte&quot; pour la voir",

"Customization options"
=> "Ajustez-vous comment votre carte appara&icirc;tra",

"Choose a frame style for your card"
=> "Choisissez un style des tables pour votre carte",

"Outside frame" => "Une table externe",

"Inside frame" => "Une table pour le texte",

"Choose a color for your card"
=> "Choisissez une couleur pour votre carte",

"Add, modify or remove custom title?"
=> "Ajoutez, modifiez ou enlevez le titre?",

"Yes" => "Oui",
"No" => "Non",

"Add description to bottom of picture on card?"
=> "Ajoutez la description au bas de l'image?",

"Choose the style of text for your card"
=> "Choisissez le style du texte pour votre carte",

"Traditional text - plain" => "Texte traditionnel - simple",

"Traditional text - italics" => "Texte traditionnel - italiques",

"Modern text - plain" => "Texte Moderne - simple",

"Modern text - italics" => "Texte Moderne - italiques",

"Typewriter text - plain" => "Texte de machine - simple",

"Typewriter text - italics" => "Texte de machine - italiques",

"Customize this card" => "Personnalisez la carte",

"Finalize this Penguin Greeting" => "Visualisez votre carte",

# Card preview and scheduling page

"Penguin Greetings - Preview Your card"
=> "Penguin Greetings - Visualisation de la carte de voeux",

"January" => "Janvier",
"February" => "Fevrier",
"March" => "Mars",
"April" => "Avril",
"May" => "Mai",
"June" => "Juin",
"July" => "Juillet",
"August" => "Aout",
"September" => "Septembre",
"October" => "Octobre",
"November" => "Novembre",
"December" => "Decembre",

"Schedule your card to be sent:" => "Envoyez la carte de voeux quand?",

"Immediately" => "Maintenant",

"Send at:" => "&Agrave; cette date:",

"Card Preview" => "Visualisation de la carte de voeux",

"Preview your Penguin Greeting here."
=> "Regardez votre carte de voeux ici avant de l'envoyer.",

"If you are satisfied with it, press the &quot;Send&quot; button at the bottom of the page."
=> "Si vous &ecirc;tes satisfaits, cliquetez sur le bouton &quot;Envoyer cette carte&quot; en bas de la page pour envoyer la carte.",

"To change something press the &quot;back&quot; button on your browser or below."
=> "Pour modifier la carte, appuyez sur le bouton &quot;Page precedente&quot; sur votre browser ou ci-dessous.",

"If you want to send the card on some future date, make sure to enter that date on the form below before pressing the &quot;Send&quot; button."
=> "Si vous voulez envoyer la carte pour une date particulière, soyez sûr d'entrer cette date sur la forme ci-dessous avant de cliqueter sur le bouton &quot;Envoyer cette carte&quot;.",

"Send!" => "Envoyer cette carte!",

# Text email template strings.

"Dear [_1]," => "[_1],",

"[_1] has sent you a Penguin Greeting!"
=> "[_1] vous a envoye une carte de voeux!",

"If your email reader doesn't support email with images,"
=> "Si votre lecteur d'email ne peut pas visualiser l'email avec des images,",

"you can view your Penguin Greeting on the world wide web."
=> "vous pouvez regarder votre carte sur le World Wide Web.",

"Just point your browser to:"
=> "Pour regarder votre carte de cette facon, dirigez votre browser a:",

"If the above link does not work,"
=> "Si le lien ci-dessus ne fonctionne pas,",

"make sure your email reader hasn't broken the link into multiple lines,"
=> "assurez-vous que votre logiciel d'email n'a pas coupe le URL en morceaux,",

"or try the following link:"
=> "ou essayez le lien suivant:",

"and enter the following information:"
=> "et ecrivez l'information suivante",

"The text of the message from [_1] is provided below:"
=> "Le texte du message de [_1] est fourni ci-dessous:",

"We hope you enjoy your Penguin Greeting!"
=> "Nous esperons que vous appreciez votre carte de voeux!",

"This is an automated email"
=> "C'est un email automatise",

# HTML email and view card strings

"Your Penguin Greeting"
=> "Votre carte de voeux",

"A Penguin Greetings ecard.<br>Sent to you from [_1]"
=> "Votre carte de voeux.<br>Envoy&eacute;e par [_1]",

"Would you like to send a California Poppy card?"
=>"Voulez-vous envoyer une carte de voeux avec des Coquelicots de Californie?",

"Click here to access the California Poppy ecard site"
=>"Consultez les cartes de voeux avec des Coquelicots de Californie",

"Would you like to send a Four Seasons card?"
=> "Voulez-vous envoyer une carte de voeux des quatre saisons?",

"Click here to access the Four Seasons ecard site"
=> "Consultez les cartes de voeux avec des quatre saisons",

"Would you like to send a Savoring Seattle card?"
=> "Voulez-vous envoyer une carte de voeux avec des vues de Seattle?",

"Click here to access the Savoring the sights of Seattle ecard site"
=> "Consultez les cartes de voeux avec des vues de Seattle",

"You can also view your Penguin Greeting via any web browser."
=> "Vous pouvez &eacute;galement regarder votre carte de voeux avec n'importe quel web browser.",

"To view your Penguin Greeting in this way, point your browser to:"
=> "Pour regarder votre carte de cette façon, dirigez votre browser &agrave;:",

"and enter the following information"
=> "et &eacute;crivez l'information suivante",

# Card sent confirmation template strings

"Penguin Greetings - Your card has been sent!"
=> "Penguin Greetings - Votre carte a &eacute;t&eacute; envoy&eacute;e!",

"Your card has been sent!"
=> "Votre carte a &eacute;t&eacute; envoy&eacute;e!",

"Would you like to send a Christmas card?"
=> "Voulez-vous envoyer une carte de No&euml;l?",

"Click here to access the Penguin Greetings Christmas card site"
=> "Consultez les cartes de No&euml;l",

"Want to send another Four Seasons card?"
=> "Voulez envoyer une autre carte de voeux des quatre saisons?",

"Want to send another Penguin Greeting?"
=> "Voulez envoyer une autre carte de voeux?",

"Send another card"
=> "Envoyez une autre carte",

"Return to Penguin Greetings start page"
=> "Consultez les autres cartes de voeux",

# Field Error template and error strings

"Penguin Greeting Error"
=> "Erreur - Cartes de voeux",

# Field error translations
'Field was left empty'
=> 'L\'information demandee est absente',
'Field was too short'
=> 'L\'information était trop courte',
'Field was too long'
=> 'L\'information etait trop longue',
'Only a number was expected (without a decimal point)'
=> 'La reponse numerique a ete prevue',
'Only a number was expected'
=> 'La reponse numerique a ete prevue',
'Only letter and numbers were expected (no punctuation)'
=> 'On ne permet aucune ponctuation dans cette reponse',
'No letters or numbers are allowed in this field'
=> 'On ne permet aucune lettre ou nombre dans cette réponse',
'Not one of the allowed values'
=> 'Cette reponse ne correspond pas a une des valeurs admises',
'Field didn\'t match pattern'
=> 'Cette reponse ne correspond pas au modele prevu',
'Field not a valid email address'
=> 'La reponse n\'est pas un email valide',
'Field not a valid telephone number'
=> 'La reponse n\'est pas un numero de telephone valide',
'Field not a valid date'
=> 'La reponse n\'est pas une date valide',

# Field name translations
message => 'Votre message',
recipient_name => 'Nom du destinataire',
'recipient_name-2' => 'Nom du destinataire #2',
'recipient_name-3' => 'Nom du destinataire #3',
'recipient_name-4' => 'Nom du destinataire #4',
'recipient_name-5' => 'Nom du destinataire #5',
recipient_email => 'Email du destinataire',
'recipient_email-2' => 'Email du destinataire #2',
'recipient_email-3' => 'Email du destinataire #3',
'recipient_email-4' => 'Email du destinataire #4',
'recipient_email-5' => 'Email du destinataire #5',
sender_name => 'Votre nom',
sender_email => 'Votre email',
password => 'Mot de passe',

"Error:" => "Erreur:",

"Missing or incomplete form information"
=> "Certaines informations que vous avez fournies &eacute;taient manquantes ou incorrectes",

"The following fields below are either missing information or the supplied information doesn't match what was asked for."
=> "Une partie d'information demand&eacute;e est absente ou les informations que vous avez fournies ne sont pas identique qu'a &eacute;t&eacute; demand&eacute;.",

"Please use the back button to correct these fields and then resubmit the form."
=> "Retournez et corrigez les erreurs si vous plait.",

"Go back and correct errors"
=> "Retournez pour corriger les erreurs",

'Unknown Penguin Greeting Error'
=> 'Erreur inconnue de logiciel',

"Penguin Greetings cannot complete the operation because of a unknown application error.  Please contact the system administrator."
=>  "Le logiciel Penguin Greetings ne peut pas accomplir l\'opéeration demandée due a une erreur inconnue.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Unknown operation requested'
=> 'Demande d\'une operation inconnue',

"Penguin Greetings cannot complete the operation because of a configuration error resulting in an unknown request.  Please contact the system administrator."
=> "L'operation demandee du logiciel Penguin Greetings est inconnue.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'No template to display'
=> 'Ne peut pas localiser le template de page Web',

"Penguin Greetings has been misconfigured and has no HTML template to display after processing this request.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings a rencontré une erreur preservant l\'information ecrite par l\'utilisateur.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Error preserving user selections'
=>'Erreur preservant l\'information ecrite par l\'utilisateur',

"Penguin Greetings has encountered an error attempting to save your selections in between menu screens.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings a rencontré une erreur preservant l\'information ecrite par l\'utilisateur.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Missing Penguin Greetings site'
=> 'Site de cartes de voeux absent',

"You are attempting to access a Penguin Greetings e-card site that either no longer exists on this server or has been relocated."
=> "Vous essayez d'acceder a une site de cartes de voeux que n'existe plus sur ce serveur ou a ete deplace.",

'Misconfigured Secondary Penguin Greetings site'
=> 'Erreur de configuration d\'une site de cartes secondaire',

"The secondary ecard site you are trying to access has encountered an unrecoverable configuration error.   Please contact the system administrator."
=> "La site de cartes que vous essayez d'acceder a rencontre une erreur de configuration.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Unable to open file'
=> 'Incapable d\'ouvrir un fichier',

"Penguin Greetings is misconfigured or damaged and cannot open a file.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings est incorrectement configure ou endommage et ne peut pas ouvrir un fichier.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Unable to close file'
=> 'Incapable de fermer un fichier',

"Penguin Greetings is misconfigured or damaged and cannot close a file.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings est incorrectement configure ou endommage et ne peut pas fermer un fichier.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Unable to read file'
=> 'Incapable de lire un fichier',

"Penguin Greetings is misconfigured or damaged and cannot read a file.    Please contact the system administrator."
=>  "Le logiciel Penguin Greetings est incorrectement configure ou endommage et ne peut pas lire un fichier.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Unable to write file'
=> 'Incapable d\'ecrire un fichier',

"Penguin Greetings is misconfigured or damaged and cannot write to a file.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings est incorrectement configure ou endommage et ne peut pas ecrire un fichier.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Data file corrupted'
=> 'fichier electronique endommage',

"Penguin Greetings is misconfigured or damaged and has found a corrupted data file.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings est incorrectement configure ou endommage et a trouve un fichier electronique endommage  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Card does not exist'
=> 'Carte de voeux n\'existe pas',

"The card that was sent to you no longer exists in this system, or Penguin Greetings is misconfigured or damaged.  Please contact the system administrator."
=> "La carte de voeux qui ete envoyee a vous n'existe plus sur ce systeme ou le logiciel Penguin Greetings est incorrectement configure ou endommage.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Date related processing error'
=> 'Erreur associee au traitement de date',

"Penguin Greetings is misconfigured or damaged and cannot process the date given.    Please contact the system administrator."
=> "Le logiciel Penguin Greetings est incorrectement configure ou endommage et ne peut pas traiter la date donnee.  Contactez l\'operateur de cet ordinateur d\'Internet s'il vous plait.",

'Impossible date'
=> 'Date logiquement impossible',

"The date you have given is not a valid date in our calendar"
=> "La date que vous avez donnee n\'est pas une date valide dans notre calendrier",

'Date must be in the future'
=> 'La date doit etre a l\'avenir',

"The date you have entered has already passed.  Please give a date which is in the future."
=>  "La date que vous avez donnee est deja passee.  Donnez une date qui est a l\'avenir s'il vous plait.",

'Login and password do not match'
=> 'Votre ouverture et mot de passe n\'ont pas ete acceptes',

"The login and password you have given were not recognized on this server"
=> "Votre ouverture et mot de passe ne sont pas identifies sur cet ordinateur",


'Card ID and password do not match'
=>  'Votre Nom de Carte et mot de passe n\'ont pas ete acceptes',

"The card ID and the password were not recognized on this server"
=> "Votre Nom de Carte et mot de passe ne sont pas identifies sur cet ordinateur",

'Card session probably expired'
=> 'La periode pour ecrire votre carte a expire',

"You are trying to continue with a session that no longer has a stored state file.  You probably waited too long before continuing.  Please log back into the start of Penguin Greetings and begin your card again."
=> "Vous essayez probablement de finir ecrire une carte apres avoir attendu trop longtemps. Allez de nouveau a la premiere page d'logiciel et recommencez votre carte encore s'il vous plait.",

"Please go back and correct this error."
=> "Retournez et corrigez les erreurs si vous plait.",

"Error No:" => "Nombre D'Erreur",
);
# fin de lexique.

=head1 NAME

Pgreet::I18N::fr_fr  -  Locale::Maketext localization for Penguin Greetings

=head1 DESCRIPTION

This module is part of the L<Locale::Maketext> localization of
secondary ecard sites of Penguin Greetings.  See the
L<Locale::Maketext> documentation for more information on using this
scheme for handling Internationalization/Localization.

=head1 COPYRIGHT

Copyright (c) 2003-2005 Edouard Lagache

This software is released under the GNU General Public License, Version 2.
For more information, see the COPYING file included with this software or
visit: http://www.gnu.org/copyleft/gpl.html

=head1 BUGS

No known bugs at this time.

=head1 AUTHOR

Edouard Lagache <pgreetdev@canebas.org>

=head1 VERSION

1.0.0

=head1 SEE ALSO

L<Locale::Maketext>, L<File::Findgrep>

=cut

1;  # fin de module.


# automatically generated file, don't edit



# Copyright 2011 David Cantrell, derived from data from libphonenumber
# http://code.google.com/p/libphonenumber/
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
package Number::Phone::StubCountry::GR;
use base qw(Number::Phone::StubCountry);

use strict;
use warnings;
use utf8;
our $VERSION = 1.20200309202346;

my $formatters = [
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '
            21|
            7
          ',
                  'pattern' => '(\\d{2})(\\d{4})(\\d{4})'
                },
                {
                  'format' => '$1 $2',
                  'leading_digits' => '
            2(?:
              2|
              3[2-57-9]|
              4[2-469]|
              5[2-59]|
              6[2-9]|
              7[2-69]|
              8[2-49]
            )|
            5
          ',
                  'pattern' => '(\\d{4})(\\d{6})'
                },
                {
                  'format' => '$1 $2 $3',
                  'leading_digits' => '[2689]',
                  'pattern' => '(\\d{3})(\\d{3})(\\d{4})'
                }
              ];

my $validators = {
                'fixed_line' => '
          2(?:
            1\\d\\d|
            2(?:
              2[1-46-9]|
              [36][1-8]|
              4[1-7]|
              5[1-4]|
              7[1-5]|
              [89][1-9]
            )|
            3(?:
              1\\d|
              2[1-57]|
              [35][1-3]|
              4[13]|
              7[1-7]|
              8[124-6]|
              9[1-79]
            )|
            4(?:
              1\\d|
              2[1-8]|
              3[1-4]|
              4[13-5]|
              6[1-578]|
              9[1-5]
            )|
            5(?:
              1\\d|
              [29][1-4]|
              3[1-5]|
              4[124]|
              5[1-6]
            )|
            6(?:
              1\\d|
              [269][1-6]|
              3[1245]|
              4[1-7]|
              5[13-9]|
              7[14]|
              8[1-5]
            )|
            7(?:
              1\\d|
              2[1-5]|
              3[1-6]|
              4[1-7]|
              5[1-57]|
              6[135]|
              9[125-7]
            )|
            8(?:
              1\\d|
              2[1-5]|
              [34][1-4]|
              9[1-57]
            )
          )\\d{6}
        ',
                'geographic' => '
          2(?:
            1\\d\\d|
            2(?:
              2[1-46-9]|
              [36][1-8]|
              4[1-7]|
              5[1-4]|
              7[1-5]|
              [89][1-9]
            )|
            3(?:
              1\\d|
              2[1-57]|
              [35][1-3]|
              4[13]|
              7[1-7]|
              8[124-6]|
              9[1-79]
            )|
            4(?:
              1\\d|
              2[1-8]|
              3[1-4]|
              4[13-5]|
              6[1-578]|
              9[1-5]
            )|
            5(?:
              1\\d|
              [29][1-4]|
              3[1-5]|
              4[124]|
              5[1-6]
            )|
            6(?:
              1\\d|
              [269][1-6]|
              3[1245]|
              4[1-7]|
              5[13-9]|
              7[14]|
              8[1-5]
            )|
            7(?:
              1\\d|
              2[1-5]|
              3[1-6]|
              4[1-7]|
              5[1-57]|
              6[135]|
              9[125-7]
            )|
            8(?:
              1\\d|
              2[1-5]|
              [34][1-4]|
              9[1-57]
            )
          )\\d{6}
        ',
                'mobile' => '
          68[57-9]\\d{7}|
          (?:
            69|
            94
          )\\d{8}
        ',
                'pager' => '',
                'personal_number' => '70\\d{8}',
                'specialrate' => '(
          8(?:
            0[16]|
            12|
            25
          )\\d{7}
        )|(90[19]\\d{7})|(5005000\\d{3})',
                'toll_free' => '800\\d{7}',
                'voip' => ''
              };
my %areanames = ();
$areanames{el}->{3021} = "Αθήνα\/Πειραιάς\/Σαλαμίνα";
$areanames{el}->{302221} = "Χαλκίδα";
$areanames{el}->{302222} = "Κύμη";
$areanames{el}->{302223} = "Αλιβέρι";
$areanames{el}->{302224} = "Κάρυστος";
$areanames{el}->{302226} = "Αιδηψός";
$areanames{el}->{302227} = "Μαντούδι";
$areanames{el}->{302228} = "Ψαχνά";
$areanames{el}->{302229} = "Ερέτρια";
$areanames{el}->{302231} = "Λαμία";
$areanames{el}->{302232} = "Δομοκός";
$areanames{el}->{302233} = "Αταλάντη";
$areanames{el}->{302234} = "Αμφίκλεια";
$areanames{el}->{302235} = "Καμμένα\ Βούρλα";
$areanames{el}->{302236} = "Μακρακώμη";
$areanames{el}->{302237} = "Καρπενήσι";
$areanames{el}->{302238} = "Στυλίδα";
$areanames{el}->{302241} = "Ρόδος";
$areanames{el}->{302242} = "Κως";
$areanames{el}->{302243} = "Κάλυμνος";
$areanames{el}->{302244} = "Αρχάγγελος";
$areanames{el}->{302245} = "Κάρπαθος";
$areanames{el}->{302246} = "Τήλος\/Σύμη\/Χάλκη\/Μεγίστη";
$areanames{el}->{302247} = "Λέρος";
$areanames{el}->{302251} = "Μυτιλήνη";
$areanames{el}->{302252} = "Αγιάσος\/Πλωμάρι";
$areanames{el}->{302253} = "Καλλονή\/Μήθυμνα";
$areanames{el}->{302254} = "Άγιος\ Ευστράτιος\/Μούδρος\/Μύρινα";
$areanames{el}->{302261} = "Λειβαδιά";
$areanames{el}->{302262} = "Θήβα";
$areanames{el}->{302263} = "Βίλια";
$areanames{el}->{302264} = "Δόμβραινα";
$areanames{el}->{302265} = "Άμφισσα";
$areanames{el}->{302266} = "Λιδορίκι";
$areanames{el}->{302267} = "Δίστομο";
$areanames{el}->{302268} = "Αλίαρτος";
$areanames{el}->{302271} = "Χίος";
$areanames{el}->{302272} = "Καρδάμυλα";
$areanames{el}->{302273} = "Σάμος";
$areanames{el}->{302274} = "Βολισσός";
$areanames{el}->{302275} = "Άγιος\ Κήρυκος";
$areanames{el}->{302281} = "Σύρος";
$areanames{el}->{302282} = "Άνδρος";
$areanames{el}->{302283} = "Τήνος";
$areanames{el}->{302284} = "Πάρος";
$areanames{el}->{302285} = "Νάξος";
$areanames{el}->{302286} = "Θήρα";
$areanames{el}->{302287} = "Μήλος";
$areanames{el}->{302288} = "Κέα";
$areanames{el}->{302289} = "Μύκονος";
$areanames{el}->{302291} = "Λαγονήσι";
$areanames{el}->{302292} = "Λαύριο";
$areanames{el}->{302293} = "Άγιος\ Σωτήρας";
$areanames{el}->{302294} = "Ραφήνα";
$areanames{el}->{302295} = "Αφίδναι";
$areanames{el}->{302296} = "Μέγαρα\/Νέα\ Πέραμος";
$areanames{el}->{302297} = "Αίγινα";
$areanames{el}->{302298} = "Μέθανα\/Πόρος\/Σπέτσες";
$areanames{el}->{302299} = "Μαρκόπουλο";
$areanames{el}->{30231} = "Θεσσαλονίκη";
$areanames{el}->{302321} = "Σέρρες";
$areanames{el}->{302322} = "Νιγρίτα";
$areanames{el}->{302323} = "Σιδηρόκαστρο";
$areanames{el}->{302324} = "Νέα\ Ζίχνη";
$areanames{el}->{302325} = "Ηράκλεια\,\ Σερρών";
$areanames{el}->{302327} = "Ροδόπολη\,\ Σερρών";
$areanames{el}->{302331} = "Βέροια";
$areanames{el}->{302332} = "Νάουσα";
$areanames{el}->{302333} = "Αλεξάνδρεια";
$areanames{el}->{302341} = "Κιλκίς";
$areanames{el}->{302343} = "Πολύκαστρο";
$areanames{el}->{302351} = "Κατερίνη";
$areanames{el}->{302352} = "Λιτόχωρο";
$areanames{el}->{302353} = "Αιγίνιο";
$areanames{el}->{302371} = "Πολύγυρος";
$areanames{el}->{302372} = "Αρναία";
$areanames{el}->{302373} = "Νέα\ Μουδανιά";
$areanames{el}->{302374} = "Κασσάνδρεια";
$areanames{el}->{302375} = "Νικήτη";
$areanames{el}->{302376} = "Στρατώνι";
$areanames{el}->{302377} = "Άγιον\ Όρος\/Ιερισσός";
$areanames{el}->{302381} = "Έδεσσα";
$areanames{el}->{302382} = "Γιαννιτσά";
$areanames{el}->{302384} = "Αριδαία";
$areanames{el}->{302385} = "Φλώρινα";
$areanames{el}->{302386} = "Αμύνταιο";
$areanames{el}->{302391} = "Χαλκηδόνα";
$areanames{el}->{302392} = "Περαία";
$areanames{el}->{302393} = "Λαγκαδίκια";
$areanames{el}->{302394} = "Λαγκαδάς";
$areanames{el}->{302395} = "Σοχός";
$areanames{el}->{302396} = "Βασιλικά";
$areanames{el}->{302397} = "Ασπροβάλτα";
$areanames{el}->{302399} = "Καλλικράτεια";
$areanames{el}->{30241} = "Λάρισα";
$areanames{el}->{302421} = "Βόλος";
$areanames{el}->{302422} = "Αλμυρός";
$areanames{el}->{302423} = "Καλά\ Νερά";
$areanames{el}->{302424} = "Σκόπελος";
$areanames{el}->{302425} = "Βελεστίνο";
$areanames{el}->{302426} = "Ζαγορά";
$areanames{el}->{302427} = "Σκιάθος";
$areanames{el}->{302431} = "Τρίκαλα";
$areanames{el}->{302432} = "Καλαμπάκα";
$areanames{el}->{302433} = "Φαρκαδόνα";
$areanames{el}->{302434} = "Πύλη";
$areanames{el}->{302441} = "Καρδίτσα";
$areanames{el}->{302443} = "Σοφάδες";
$areanames{el}->{302444} = "Παλαμάς";
$areanames{el}->{302445} = "Μουζάκι";
$areanames{el}->{302461} = "Κοζάνη";
$areanames{el}->{302462} = "Γρεβενά";
$areanames{el}->{302463} = "Πτολεμαΐδα";
$areanames{el}->{302464} = "Σέρβια";
$areanames{el}->{302465} = "Σιάτιστα";
$areanames{el}->{302467} = "Καστοριά";
$areanames{el}->{302468} = "Νεάπολη";
$areanames{el}->{302491} = "Φάρσαλα";
$areanames{el}->{302492} = "Τύρναβος";
$areanames{el}->{302493} = "Ελασσόνα";
$areanames{el}->{302494} = "Αγιά";
$areanames{el}->{302495} = "Γόννοι\/Μακρυχώρι";
$areanames{el}->{30251} = "Καβάλα";
$areanames{el}->{302521} = "Δράμα";
$areanames{el}->{302522} = "Προσοτσάνη";
$areanames{el}->{302523} = "Κάτω\ Νευροκόπι";
$areanames{el}->{302524} = "Παρανέστι";
$areanames{el}->{302531} = "Κομοτηνή";
$areanames{el}->{302532} = "Σάπες";
$areanames{el}->{302533} = "Ξυλαγανή";
$areanames{el}->{302534} = "Ίασμος";
$areanames{el}->{302535} = "Νέα\ Καλλίστη";
$areanames{el}->{302541} = "Ξάνθη";
$areanames{el}->{302542} = "Σταυρούπολη";
$areanames{el}->{302544} = "Εχίνος";
$areanames{el}->{302551} = "Αλεξανδρούπολη";
$areanames{el}->{302552} = "Ορεστιάδα";
$areanames{el}->{302553} = "Διδυμότειχο";
$areanames{el}->{302554} = "Σουφλί";
$areanames{el}->{302555} = "Φέρες";
$areanames{el}->{302556} = "Κυπρίνος";
$areanames{el}->{302591} = "Χρυσούπολη";
$areanames{el}->{302592} = "Ελευθερούπολη";
$areanames{el}->{302593} = "Θάσος";
$areanames{el}->{302594} = "Νέα\ Πέραμος\ Καβάλας";
$areanames{el}->{30261} = "Πάτρα";
$areanames{el}->{302621} = "Πύργος";
$areanames{el}->{302622} = "Αμαλιάδα";
$areanames{el}->{302623} = "Λεχαινά";
$areanames{el}->{302624} = "Αρχαία\ Ολυμπία";
$areanames{el}->{302625} = "Κρέστενα";
$areanames{el}->{302626} = "Ανδρίτσαινα";
$areanames{el}->{302631} = "Μεσολόγγι";
$areanames{el}->{302632} = "Αιτωλικό";
$areanames{el}->{302634} = "Ναύπακτος";
$areanames{el}->{302635} = "Ματαράγκα";
$areanames{el}->{302641} = "Αγρίνιο";
$areanames{el}->{302642} = "Αμφιλοχία";
$areanames{el}->{302643} = "Βόνιτσα";
$areanames{el}->{302644} = "Θερμό";
$areanames{el}->{302645} = "Λευκάδα";
$areanames{el}->{302647} = "Νέο\ Χαλκιόπουλο\/Φυτείες";
$areanames{el}->{302651} = "Ιωάννινα";
$areanames{el}->{302653} = "Καρυές\ Ασπραγγέλων";
$areanames{el}->{302655} = "Κόνιτσα\/Πέρδικα\ Δωδώνης";
$areanames{el}->{302656} = "Μέτσοβο";
$areanames{el}->{302657} = "Δελβινάκι";
$areanames{el}->{302658} = "Ζίτσα";
$areanames{el}->{302659} = "Καλέντζι\ Δωδώνης";
$areanames{el}->{302661} = "Κέρκυρα";
$areanames{el}->{302662} = "Λευκίμμη";
$areanames{el}->{302663} = "Σκριπερό";
$areanames{el}->{302664} = "Φιλιάτες";
$areanames{el}->{302665} = "Ηγουμενίτσα";
$areanames{el}->{302666} = "Παραμυθιά";
$areanames{el}->{302671} = "Αργοστόλι";
$areanames{el}->{302674} = "Σάμη";
$areanames{el}->{302681} = "Άρτα";
$areanames{el}->{302682} = "Πρέβεζα";
$areanames{el}->{302683} = "Φιλιππιάδα";
$areanames{el}->{302684} = "Καναλλάκι";
$areanames{el}->{302685} = "Βουργαρέλι";
$areanames{el}->{302691} = "Αίγιο";
$areanames{el}->{302692} = "Καλάβρυτα";
$areanames{el}->{302693} = "Κάτω\ Αχαΐα";
$areanames{el}->{302694} = "Χαλανδρίτσα";
$areanames{el}->{302695} = "Ζάκυνθος";
$areanames{el}->{302696} = "Ακράτα";
$areanames{el}->{30271} = "Τρίπολη";
$areanames{el}->{302721} = "Καλαμάτα";
$areanames{el}->{302722} = "Μεσσήνη";
$areanames{el}->{302723} = "Πύλος";
$areanames{el}->{302724} = "Μελιγαλάς";
$areanames{el}->{302725} = "Κορώνη\ Πυλίας";
$areanames{el}->{302731} = "Σπάρτη";
$areanames{el}->{302732} = "Μολάοι";
$areanames{el}->{302733} = "Γύθειο";
$areanames{el}->{302734} = "Νεάπολη";
$areanames{el}->{302735} = "Σκάλα";
$areanames{el}->{302736} = "Κύθηρα";
$areanames{el}->{302741} = "Κόρινθος";
$areanames{el}->{302742} = "Κιάτο";
$areanames{el}->{302743} = "Ξυλόκαστρο";
$areanames{el}->{302744} = "Λουτράκι";
$areanames{el}->{302746} = "Νεμέα";
$areanames{el}->{302747} = "Καλιανοί";
$areanames{el}->{302751} = "Άργος";
$areanames{el}->{302752} = "Ναύπλιο";
$areanames{el}->{302753} = "Λυγουριό";
$areanames{el}->{302754} = "Κρανίδι";
$areanames{el}->{302755} = "Άστρος";
$areanames{el}->{302757} = "Λεωνίδιο";
$areanames{el}->{302761} = "Κυπαρισσία";
$areanames{el}->{302763} = "Γαργαλιάνοι";
$areanames{el}->{302765} = "Κοπανάκι";
$areanames{el}->{302791} = "Μεγαλόπολη";
$areanames{el}->{302792} = "Καστρί\ Κυνουρίας";
$areanames{el}->{302795} = "Βυτίνα";
$areanames{el}->{302796} = "Λεβίδι";
$areanames{el}->{302797} = "Τροπαία";
$areanames{el}->{30281} = "Ηράκλειο";
$areanames{el}->{302821} = "Χανιά";
$areanames{el}->{302822} = "Κίσσαμος";
$areanames{el}->{302823} = "Κάντανος";
$areanames{el}->{302824} = "Κολυμβάρι";
$areanames{el}->{302825} = "Βάμος";
$areanames{el}->{302831} = "Ρέθυμνο";
$areanames{el}->{302832} = "Σπήλι";
$areanames{el}->{302833} = "Αμάρι";
$areanames{el}->{302834} = "Πέραμα\ Μυλοποτάμου";
$areanames{el}->{302841} = "Άγιος\ Νικόλαος";
$areanames{el}->{302842} = "Ιεράπετρα";
$areanames{el}->{302843} = "Σητεία";
$areanames{el}->{302844} = "Τζερμιάδο";
$areanames{el}->{302891} = "Αρκαλοχώρι";
$areanames{el}->{302892} = "Μοίρες\,\ Ηράκλειο";
$areanames{el}->{302893} = "Πύργος\,\ Κρήτη";
$areanames{el}->{302894} = "Αγία\ Βαρβάρα\,\ Ηράκλειο\ Κρήτης";
$areanames{el}->{302895} = "Άνω\ Βιάννος";
$areanames{el}->{302897} = "Λιμένας\ Χερσονήσου";
$areanames{en}->{3021} = "Athens\/Piraeus\/Salamina";
$areanames{en}->{302221} = "Chalcis";
$areanames{en}->{302222} = "Kymi";
$areanames{en}->{302223} = "Aliveri";
$areanames{en}->{302224} = "Karystos";
$areanames{en}->{302226} = "Aidipsos";
$areanames{en}->{302227} = "Kireas";
$areanames{en}->{302228} = "Messapia";
$areanames{en}->{302229} = "Eretria";
$areanames{en}->{302231} = "Lamia";
$areanames{en}->{302232} = "Domokos";
$areanames{en}->{302233} = "Atalanta";
$areanames{en}->{302234} = "Amfikleia";
$areanames{en}->{302235} = "Kamena\ Vourla";
$areanames{en}->{302236} = "Makrakomi";
$areanames{en}->{302237} = "Karpenisi";
$areanames{en}->{302238} = "Stylida";
$areanames{en}->{302241} = "Rhodes";
$areanames{en}->{302242} = "Kos";
$areanames{en}->{302243} = "Kalymnos";
$areanames{en}->{302244} = "Archangelos\,\ Rhodes";
$areanames{en}->{302245} = "Karpathos";
$areanames{en}->{302246} = "Salakos\,\ Rhodes";
$areanames{en}->{302247} = "Leros";
$areanames{en}->{302251} = "Mytilene";
$areanames{en}->{302252} = "Agiasos\/Plomari";
$areanames{en}->{302253} = "Kalloni\,\ Lesbos";
$areanames{en}->{302254} = "Agios\ Efstratios";
$areanames{en}->{302261} = "Livadeia";
$areanames{en}->{302262} = "Thebes";
$areanames{en}->{302263} = "Vilia";
$areanames{en}->{302264} = "Thisvi";
$areanames{en}->{302265} = "Amfissa";
$areanames{en}->{302266} = "Lidoriki";
$areanames{en}->{302267} = "Distomo";
$areanames{en}->{302268} = "Aliartos";
$areanames{en}->{302271} = "Chios";
$areanames{en}->{302272} = "Kardamyla";
$areanames{en}->{302273} = "Samos";
$areanames{en}->{302274} = "Psara\,\ Chios";
$areanames{en}->{302275} = "Agios\ Kirykos";
$areanames{en}->{302281} = "Ano\ Syros";
$areanames{en}->{302282} = "Andros";
$areanames{en}->{302283} = "Tinos";
$areanames{en}->{302284} = "Paros";
$areanames{en}->{302285} = "Naxos";
$areanames{en}->{302286} = "Santorini";
$areanames{en}->{302287} = "Milos";
$areanames{en}->{302288} = "Kea";
$areanames{en}->{302289} = "Mykonos";
$areanames{en}->{302291} = "Lagonisi";
$areanames{en}->{302292} = "Lavrio";
$areanames{en}->{302293} = "Agia\ Sotira";
$areanames{en}->{302294} = "Rafina";
$areanames{en}->{302295} = "Afidnes";
$areanames{en}->{302296} = "Megara";
$areanames{en}->{302297} = "Aegina";
$areanames{en}->{302298} = "Troezen\/Poros\/Hydra\/Spetses";
$areanames{en}->{302299} = "Markopoulo\ Mesogaias";
$areanames{en}->{30231} = "Thessaloniki";
$areanames{en}->{302321} = "Serres";
$areanames{en}->{302322} = "Nigrita";
$areanames{en}->{302323} = "Sidirokastro";
$areanames{en}->{302324} = "Nea\ Zichni";
$areanames{en}->{302325} = "Irakleia\,\ Serres";
$areanames{en}->{302327} = "Rodopoli";
$areanames{en}->{302331} = "Veria";
$areanames{en}->{302332} = "Naousa\,\ Imathia";
$areanames{en}->{302333} = "Alexandria";
$areanames{en}->{302341} = "Kilkis";
$areanames{en}->{302343} = "Polykastro";
$areanames{en}->{302351} = "Korinos";
$areanames{en}->{302352} = "Litochoro";
$areanames{en}->{302353} = "Aiginio";
$areanames{en}->{302371} = "Polygyros";
$areanames{en}->{302372} = "Arnaia";
$areanames{en}->{302373} = "Nea\ Moudania";
$areanames{en}->{302374} = "Kassandreia";
$areanames{en}->{302375} = "Nikiti";
$areanames{en}->{302376} = "Stratoni";
$areanames{en}->{302377} = "Ierissos\/Mount\ Athos";
$areanames{en}->{302381} = "Edessa";
$areanames{en}->{302382} = "Giannitsa";
$areanames{en}->{302384} = "Aridaia";
$areanames{en}->{302385} = "Florina";
$areanames{en}->{302386} = "Amyntaio";
$areanames{en}->{302391} = "Chalkidona";
$areanames{en}->{302392} = "Peraia\,\ Thessaloniki";
$areanames{en}->{302393} = "Lagkadikia";
$areanames{en}->{302394} = "Lagkadas";
$areanames{en}->{302395} = "Sochos";
$areanames{en}->{302396} = "Vasilika";
$areanames{en}->{302397} = "Asprovalta";
$areanames{en}->{302399} = "Kallikrateia";
$areanames{en}->{30241} = "Larissa";
$areanames{en}->{302421} = "Volos";
$areanames{en}->{302422} = "Almyros";
$areanames{en}->{302423} = "Kala\ Nera";
$areanames{en}->{302424} = "Skopelos";
$areanames{en}->{302425} = "Feres\,\ Magnesia";
$areanames{en}->{302426} = "Zagora";
$areanames{en}->{302427} = "Skiathos";
$areanames{en}->{302431} = "Trikala";
$areanames{en}->{302432} = "Kalabaka";
$areanames{en}->{302433} = "Farkadona";
$areanames{en}->{302434} = "Pyli";
$areanames{en}->{302441} = "Karditsa";
$areanames{en}->{302443} = "Sofades";
$areanames{en}->{302444} = "Palamas";
$areanames{en}->{302445} = "Mouzaki";
$areanames{en}->{302461} = "Kozani";
$areanames{en}->{302462} = "Grevena";
$areanames{en}->{302463} = "Ptolemaida";
$areanames{en}->{302464} = "Servia";
$areanames{en}->{302465} = "Siatista";
$areanames{en}->{302467} = "Kastoria";
$areanames{en}->{302468} = "Neapoli";
$areanames{en}->{302491} = "Farsala";
$areanames{en}->{302492} = "Tyrnavos";
$areanames{en}->{302493} = "Elassona";
$areanames{en}->{302494} = "Agia";
$areanames{en}->{302495} = "Gonnoi\/Makrychori";
$areanames{en}->{30251} = "Kavala";
$areanames{en}->{302521} = "Drama";
$areanames{en}->{302522} = "Prosotsani";
$areanames{en}->{302523} = "Kato\ Nevrokopi";
$areanames{en}->{302524} = "Paranesti";
$areanames{en}->{302531} = "Komotini";
$areanames{en}->{302532} = "Sapes";
$areanames{en}->{302533} = "Xylagani";
$areanames{en}->{302534} = "Iasmos";
$areanames{en}->{302535} = "Nea\ Kallisti";
$areanames{en}->{302541} = "Xanthi";
$areanames{en}->{302542} = "Stavroupoli";
$areanames{en}->{302544} = "Echinos";
$areanames{en}->{302551} = "Alexandroupoli";
$areanames{en}->{302552} = "Orestiada";
$areanames{en}->{302553} = "Didymoteicho";
$areanames{en}->{302554} = "Soufli";
$areanames{en}->{302555} = "Feres\,\ Evros";
$areanames{en}->{302556} = "Kyprinos";
$areanames{en}->{302591} = "Chrysoupoli";
$areanames{en}->{302592} = "Eleftheroupoli";
$areanames{en}->{302593} = "Thasos";
$areanames{en}->{302594} = "Nea\ Peramos\,\ Kavala";
$areanames{en}->{30261} = "Patras";
$areanames{en}->{302621} = "Burgas";
$areanames{en}->{302622} = "Amaliada";
$areanames{en}->{302623} = "Lechaina";
$areanames{en}->{302624} = "Olympia";
$areanames{en}->{302625} = "Krestena";
$areanames{en}->{302626} = "Andritsaina";
$areanames{en}->{302631} = "Messolonghi";
$areanames{en}->{302632} = "Aitoliko";
$areanames{en}->{302634} = "Nafpaktos";
$areanames{en}->{302635} = "Mataranga";
$areanames{en}->{302641} = "Agrinio";
$areanames{en}->{302642} = "Amfilochia";
$areanames{en}->{302643} = "Vonitsa";
$areanames{en}->{302644} = "Thermo";
$areanames{en}->{302645} = "Lefkada";
$areanames{en}->{302647} = "Fyteies";
$areanames{en}->{302651} = "Ioannina";
$areanames{en}->{302653} = "Asprangeli";
$areanames{en}->{302655} = "Konitsa";
$areanames{en}->{302656} = "Metsovo";
$areanames{en}->{302657} = "Delvinaki";
$areanames{en}->{302658} = "Zitsa";
$areanames{en}->{302659} = "Kalentzi";
$areanames{en}->{302661} = "Corfu";
$areanames{en}->{302662} = "Lefkimmi";
$areanames{en}->{302663} = "Corfu\ Island";
$areanames{en}->{302664} = "Filiates";
$areanames{en}->{302665} = "Igoumenitsa";
$areanames{en}->{302666} = "Paramythia";
$areanames{en}->{302671} = "Argostoli";
$areanames{en}->{302674} = "Sami\,\ Cephalonia";
$areanames{en}->{302681} = "Arta";
$areanames{en}->{302682} = "Preveza";
$areanames{en}->{302683} = "Filippiada";
$areanames{en}->{302684} = "Kanalaki";
$areanames{en}->{302685} = "Athamania";
$areanames{en}->{302691} = "Aigio";
$areanames{en}->{302692} = "Kalavryta";
$areanames{en}->{302693} = "Kato\ Achaia";
$areanames{en}->{302694} = "Chalandritsa";
$areanames{en}->{302695} = "Zakynthos";
$areanames{en}->{302696} = "Akrata";
$areanames{en}->{30271} = "Tripoli";
$areanames{en}->{302721} = "Kalamata";
$areanames{en}->{302722} = "Messene";
$areanames{en}->{302723} = "Pylos";
$areanames{en}->{302724} = "Meligalas";
$areanames{en}->{302725} = "Koroni";
$areanames{en}->{302731} = "Sparti";
$areanames{en}->{302732} = "Molaoi";
$areanames{en}->{302733} = "Gytheio";
$areanames{en}->{302734} = "Neapoli\,\ Voies";
$areanames{en}->{302735} = "Molaoi";
$areanames{en}->{302736} = "Kythera";
$areanames{en}->{302741} = "Corinth";
$areanames{en}->{302742} = "Kiato";
$areanames{en}->{302743} = "Xylokastro";
$areanames{en}->{302744} = "Loutraki";
$areanames{en}->{302746} = "Nemea";
$areanames{en}->{302747} = "Stymfalia";
$areanames{en}->{302751} = "Argos";
$areanames{en}->{302752} = "Nafplio";
$areanames{en}->{302753} = "Lygourio";
$areanames{en}->{302754} = "Kranidi";
$areanames{en}->{302755} = "Astros";
$areanames{en}->{302757} = "Leonidio";
$areanames{en}->{302761} = "Kyparissia";
$areanames{en}->{302763} = "Gargalianoi";
$areanames{en}->{302765} = "Kopanaki";
$areanames{en}->{302791} = "Megalopolis";
$areanames{en}->{302792} = "Kastri\ Kynourias";
$areanames{en}->{302795} = "Vytina";
$areanames{en}->{302796} = "Levidi";
$areanames{en}->{302797} = "Tropaia";
$areanames{en}->{30281} = "Heraklion";
$areanames{en}->{302821} = "Chania";
$areanames{en}->{302822} = "Kissamos";
$areanames{en}->{302823} = "Kandanos";
$areanames{en}->{302824} = "Kolymvari";
$areanames{en}->{302825} = "Vamos";
$areanames{en}->{302831} = "Rethymno";
$areanames{en}->{302832} = "Spyli";
$areanames{en}->{302833} = "Amari\,\ Rethymno";
$areanames{en}->{302834} = "Perama\ Mylopotamou";
$areanames{en}->{302841} = "Agios\ Nikolaos";
$areanames{en}->{302842} = "Ierapetra";
$areanames{en}->{302843} = "Sitia";
$areanames{en}->{302844} = "Tzermadio";
$areanames{en}->{302891} = "Arkalochori";
$areanames{en}->{302892} = "Moires\,\ Heraklion";
$areanames{en}->{302893} = "Pyrgos\,\ Crete";
$areanames{en}->{302894} = "Agia\ Varvara";
$areanames{en}->{302895} = "Ano\ Viannos";
$areanames{en}->{302897} = "Limenas\ Chersonisou";

    sub new {
      my $class = shift;
      my $number = shift;
      $number =~ s/(^\+30|\D)//g;
      my $self = bless({ number => $number, formatters => $formatters, validators => $validators, areanames => \%areanames}, $class);
        return $self->is_valid() ? $self : undef;
    }
1;
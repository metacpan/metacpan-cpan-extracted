--
-- Selected TOC Entries:
--
\connect - postgres

--
-- TOC Entry ID 2 (OID 66404)
--
-- Name: school___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "school___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 22 (OID 66406)
--
-- Name: material_type Type: TABLE Owner: postgres
--

CREATE TABLE "material_type" (
	"id" integer NOT NULL,
	"name" text NOT NULL
);

--
-- TOC Entry ID 4 (OID 66412)
--
-- Name: material_type___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "material_type___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 6 (OID 66420)
--
-- Name: course___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "course___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 8 (OID 66428)
--
-- Name: book___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "book___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 23 (OID 66430)
--
-- Name: publisher Type: TABLE Owner: postgres
--

CREATE TABLE "publisher" (
	"id" integer NOT NULL,
	"name" text NOT NULL
);

--
-- TOC Entry ID 10 (OID 66436)
--
-- Name: publisher___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "publisher___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 24 (OID 66438)
--
-- Name: person_type Type: TABLE Owner: postgres
--

CREATE TABLE "person_type" (
	"id" integer NOT NULL,
	"name" text NOT NULL,
	Constraint "person_type_pkey" Primary Key ("id")
);

--
-- TOC Entry ID 12 (OID 66444)
--
-- Name: person_type___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "person_type___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 14 (OID 66446)
--
-- Name: person___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "person___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 25 (OID 66448)
--
-- Name: personperson_type Type: TABLE Owner: postgres
--

CREATE TABLE "personperson_type" (
	"person_type_id" integer NOT NULL,
	"id" integer NOT NULL,
	Constraint "personperson_type_pkey" Primary Key ("person_type_id", "id")
);

--
-- TOC Entry ID 26 (OID 66451)
--
-- Name: person Type: TABLE Owner: postgres
--

CREATE TABLE "person" (
	"id" integer NOT NULL,
	"person_type_id" integer NOT NULL,
	"last_name" text NOT NULL,
	"first_name" text NOT NULL,
	"middle_name" text,
	Constraint "person_pkey" Primary Key ("id")
);

--
-- TOC Entry ID 16 (OID 66457)
--
-- Name: personperson_type___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "personperson_type___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 27 (OID 66479)
--
-- Name: course_lecturer Type: TABLE Owner: postgres
--

CREATE TABLE "course_lecturer" (
	"course_id" integer NOT NULL,
	"lecturer_id" integer NOT NULL,
	Constraint "course_lecturer_pkey" Primary Key ("course_id", "lecturer_id")
);

--
-- TOC Entry ID 28 (OID 66482)
--
-- Name: course_material Type: TABLE Owner: postgres
--

CREATE TABLE "course_material" (
	"course_id" integer NOT NULL,
	"material_type_id" integer NOT NULL,
	"material_id" integer NOT NULL
);

--
-- TOC Entry ID 29 (OID 66547)
--
-- Name: course_reader Type: TABLE Owner: postgres
--

CREATE TABLE "course_reader" (
	"id" integer NOT NULL,
	"course_id" integer NOT NULL,
	Constraint "course_reader_pkey" Primary Key ("id", "course_id")
);

--
-- TOC Entry ID 18 (OID 66550)
--
-- Name: course_reader___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "course_reader___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 30 (OID 66595)
--
-- Name: book Type: TABLE Owner: postgres
--

CREATE TABLE "book" (
	"id" integer NOT NULL,
	"name" text NOT NULL,
	"publisher_id" text,
	"author_id" integer,
	"pub_year" integer,
	Constraint "book_pkey" Primary Key ("id")
);

--
-- TOC Entry ID 31 (OID 74529)
--
-- Name: school_dept_course Type: TABLE Owner: postgres
--

CREATE TABLE "school_dept_course" (
	"school_id" integer NOT NULL,
	"dept_id" integer NOT NULL,
	"course_id" integer NOT NULL
);

--
-- TOC Entry ID 20 (OID 74536)
--
-- Name: dept___id Type: SEQUENCE Owner: postgres
--

CREATE SEQUENCE "dept___id" start 1 increment 1 maxvalue 9223372036854775807 minvalue 1 cache 1;

--
-- TOC Entry ID 32 (OID 82773)
--
-- Name: school Type: TABLE Owner: postgres
--

CREATE TABLE "school" (
	"id" integer NOT NULL,
	"name" text NOT NULL,
	"url" text,
	Constraint "school_pkey" Primary Key ("id")
);

--
-- TOC Entry ID 33 (OID 82779)
--
-- Name: dept Type: TABLE Owner: postgres
--

CREATE TABLE "dept" (
	"id" integer NOT NULL,
	"name" text NOT NULL,
	"url" text,
	"school_id" integer,
	Constraint "dept_pkey" Primary Key ("id")
);

--
-- TOC Entry ID 34 (OID 82790)
--
-- Name: temp_course1089 Type: TABLE Owner: postgres
--

CREATE TABLE "temp_course1089" (
	"id" integer,
	"name" text,
	"url" text,
	"school_id" integer,
	"description" text,
	"school_course_number" text,
	"dept_id" integer
);

--
-- TOC Entry ID 35 (OID 82817)
--
-- Name: course Type: TABLE Owner: postgres
--

CREATE TABLE "course" (
	"id" integer NOT NULL,
	"name" text NOT NULL,
	"url" text,
	"dept_id" integer,
	"school_course_number" text,
	"description" text,
	Constraint "course_pkey" Primary Key ("id")
);

--
-- TOC Entry ID 36 (OID 82839)
--
-- Name: temp_course1494 Type: TABLE Owner: postgres
--

CREATE TABLE "temp_course1494" (
	"id" integer,
	"name" text,
	"url" text,
	"dept_id" integer,
	"school_course_number" text,
	"description" text
);

--
-- TOC Entry ID 37 (OID 82861)
--
-- Name: temp_course1498 Type: TABLE Owner: postgres
--

CREATE TABLE "temp_course1498" (
	"id" integer,
	"name" text,
	"url" text,
	"dept_id" integer,
	"school_course_number" text,
	"description" text
);

--
-- TOC Entry ID 38 (OID 82883)
--
-- Name: temp_course1500 Type: TABLE Owner: postgres
--

CREATE TABLE "temp_course1500" (
	"id" integer,
	"name" text,
	"url" text,
	"dept_id" integer,
	"school_course_number" text,
	"description" text
);

--
-- TOC Entry ID 39 (OID 82905)
--
-- Name: temp_course1502 Type: TABLE Owner: postgres
--

CREATE TABLE "temp_course1502" (
	"id" integer,
	"name" text,
	"url" text,
	"dept_id" integer,
	"school_course_number" text,
	"description" text
);

--
-- Data for TOC Entry ID 43 (OID 66406)
--
-- Name: material_type Type: TABLE DATA Owner: postgres
--


COPY "material_type" FROM stdin;
1	book
25	course_reader
\.
--
-- Data for TOC Entry ID 44 (OID 66430)
--
-- Name: publisher Type: TABLE DATA Owner: postgres
--


COPY "publisher" FROM stdin;
1	Motilal Banarsidass
8	Faber
9	University of California Press
10	Prentice-Hall
11	Prentice-Hall
\.
--
-- Data for TOC Entry ID 45 (OID 66438)
--
-- Name: person_type Type: TABLE DATA Owner: postgres
--


COPY "person_type" FROM stdin;
1	lecturer
2	author
\.
--
-- Data for TOC Entry ID 46 (OID 66448)
--
-- Name: personperson_type Type: TABLE DATA Owner: postgres
--


COPY "personperson_type" FROM stdin;
1	1
2	2
\.
--
-- Data for TOC Entry ID 47 (OID 66451)
--
-- Name: person Type: TABLE DATA Owner: postgres
--


COPY "person" FROM stdin;
1	1	Malik	Aditya	\N
2	2	Burrow	Thomas	\N
3	2	Hart	George	L
4	2	Kinsley	David	R
5	1	Bryant	Edwin	
6	1	Eck	Diana	L
7	1	Witzel	Michael	
8	1	Jamison	Stephanie	W
9	1	Kuijp	Leonard	W. J. van der
10	1	Korom	Frank	
\.
--
-- Data for TOC Entry ID 48 (OID 66479)
--
-- Name: course_lecturer Type: TABLE DATA Owner: postgres
--


COPY "course_lecturer" FROM stdin;
8	1
9	1
10	1
18	1
25	5
27	5
28	6
29	7
30	7
31	7
39	8
40	8
41	8
33	7
36	7
38	7
37	7
45	10
\.
--
-- Data for TOC Entry ID 49 (OID 66482)
--
-- Name: course_material Type: TABLE DATA Owner: postgres
--


COPY "course_material" FROM stdin;
8	1	2
9	1	4
24	1	13
24	1	12
25	1	14
8	1	3
18	1	10
10	25	18
27	1	15
\.
--
-- Data for TOC Entry ID 50 (OID 66547)
--
-- Name: course_reader Type: TABLE DATA Owner: postgres
--


COPY "course_reader" FROM stdin;
18	10
\.
--
-- Data for TOC Entry ID 51 (OID 66595)
--
-- Name: book Type: TABLE DATA Owner: postgres
--


COPY "book" FROM stdin;
2	The Sanskrit Language	8	2	1959
3	A Rapid Sanskrit Method	1	3	1984
4	Hindu Goddesses: Visions of the Divine Feminine in the Hindu Religious Tradition	9	4	1986
10	Hinduism: A Cultural Perspective	10	4	1993
12	Siva Purana	\N	\N	\N
13	Devi Gita of the Goddess	\N	\N	\N
14	Bhagavad Gita	\N	\N	\N
15	Patanjali's Yoga Sutras	\N	\N	\N
\.
--
-- Data for TOC Entry ID 52 (OID 74529)
--
-- Name: school_dept_course Type: TABLE DATA Owner: postgres
--


COPY "school_dept_course" FROM stdin;
\.
--
-- Data for TOC Entry ID 53 (OID 82773)
--
-- Name: school Type: TABLE DATA Owner: postgres
--


COPY "school" FROM stdin;
2	University of Canterbury	\N
3	Harvard University	\N
6	Boston University	\N
\.
--
-- Data for TOC Entry ID 54 (OID 82779)
--
-- Name: dept Type: TABLE DATA Owner: postgres
--


COPY "dept" FROM stdin;
1	Department of Religious Studies	http://www.rels.canterbury.ac.nz	2
3	School of Divinity	http://www.hds.harvard.edu	3
2	Department of Sanskrit and Indian Studies	http://www.fas.harvard.edu/~sanskrit/	3
4	Religion	http://www.bu.edu/religion/main/religionhome.html	6
\.
--
-- Data for TOC Entry ID 55 (OID 82790)
--
-- Name: temp_course1089 Type: TABLE DATA Owner: postgres
--


COPY "temp_course1089" FROM stdin;
8	Introduction to Classical Sanskrit	http://www.rels.canterbury.ac.nz/pages/hindu.html	2	A course intended to provide a working knowledge of Sanskrit grammar and the ability to read simple texts in Sanskrit. Primarily (but not solely) intended for advancing students in Buddhist and Hindu studies.	RELS 340	1
9	Studies in Hinduism	http://www.rels.canterbury.ac.nz/pages/hindu.html	2	In this course we will be examining the sources and manifestations of feminine power in Hinduism. Whereas in Christianity, Islam, and Judaism the divine is predominantly spoken of in masculine terms, in Hinduism divinity is imagined as either being male or female (and sometimes even beyond male and female). In Hinduism the creator of the universe can thus be referred to as Goddess (devi) or "Mother" (mata) rather than God or "Father". We will be looking at the impact the idea of a feminine source of creation and destruction has on the religious imagination of culture. How do women and men relate to the divine feminine? What are the different forms that the divine feminine assumes? How is the Goddess perceived and spoken of in sacred texts, ancient and contemporary? What are some of the narratives, rituals, icons, and religious meanings involved in her worship?	RELS 311	1
10	Sex, Death and Salvation in Asian Religions	http://www.rels.canterbury.ac.nz/pages/hindu.html	2	Sex and death are inseparably intertwined in the two major religions of Asia, Buddhism and Hinduism. Sex makes the world of death and rebirth go round, and this is a problem for humans, who normally wish to avoid death and live forever. In this course, we explore how Buddhism and Hinduism construe this problem, and the many ways they seek to resolve it: by renouncing, sublimating, or embracing sex and the world that it perpetuates. Topics covered include the theory of karma and rebirth (reincarnation), Hindu and Buddhist monasticism, cosmology and cosmography, death rituals, ghosts and exorcism, religious eroticism, and tantric sex.	RELS 104	1
18	Religions of India	http://www.rels.canterbury.ac.nz/pages/hindu.html	2	This course focuses on introducing the various ideas and practices that make up Hinduism, while paying some attention to Jainism and Sikhism. In particular we will be looking at the cultural and historical conditions in which these religious traditions emerged and evolved. We will explore the multi-dimensional inter-connections between religious ideas, myth, art, music, architecture, ritual, narritive, social structure, politics and philosophy in a historical and contemporary perspective. Where possible, lectures will be supplemented by viewing relevent video documentation. The intention of the course is to provide a well-grounded overview of Indian religions and a foundation for further study.	RELS 228	1
24	Introduction to Hinduism	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	This course will attempt an Introduction to Hinduism(s) by a reading of some of the texts that have gained prominence amongst Hindus over the centuries. Readings will include extracts from the ancient Vedas, the philosophical Upanisads, the Dharma law books, psycho-meditational texts such as the Yoga Sutras, the Ramayana and Mahabharata epics, the famous Bhagavad Gita, the Siva Purana, the Devi Gita of the Goddess, devotional poetry, and modern religious writings that have become authoritative texts amongst various present-day religious groups.\n	Religion 1600	2
25	The Bhagavad Gita	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	The Bhagavad Gita is one of the best-known texts of the Hindu tradition. Incorporating elements from the oldest Vedas, concepts from the Upanishads, and features from the classical schools of Yoga, Sankhya, and Vedanta, the text serves as a base to overview much that has come to be known as Hinduism. Reading of the entire text, with special attention to a wide variety of different commentaries, ancient and modern. Consideration of the role of the text in European Romanticism, Indian nationalism, and Western neo-Hindu religious movements.\n	Religion 1614	2
27	Yoga and Ancient Indian Systems of Liberation	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	This course will consist of a close reading of Patanjalis Yoga Sutras, the earliest comprehensive manual on yoga psychology and meditation in ancient India. Further readings will include classical soteriological texts from different schools that have appropriated such meditational techniques as a means towards their various goals of liberation. These will include both monistic and theistic Hindu schools such as Kashmir Saivism, Vaishnava bhakti and Tantric Shakta schools, as well as Buddhist practices. Additional readings will examine the systems of some of the more prominent practitioners of yoga in the modern period to consider issues of innovation and continuity.	Religion 1617	2
28	Readings in Hindu Myth, Image, and Pilgrimage	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Intensive reading and research on specific topics in Hindu mythology, image and iconography, temples and temple towns, sacred geography and pilgrimage patterns.	Religion 3601	2
33	Introduction to Vedic Sanskrit and Literature	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Introduction to Vedic grammar. Selection of Vedic prose texts from the Yajurveda Samhitas, Brahmanas, Aranyakas and Upanisads. Builds on knowledge of elementary Sanskrit or Old Iranian.\n	Sanskrit 204ar	\N
35	Understanding Indian Ritual	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Investigates the indigenous theory and practice of Indian ritual, from its beginnings in the second millennium BCE (Rgveda) to present time. Stress on the development of the Agnihotra and Homa and Puja rituals, with materials from Vedic, Puranic, Tantric, and Buddhist sources, including their use in Bali, Tibet and Japan, and audio-vidual materials. Recent theories of ritual will also be discussed. Sanskrit texts are used in translation, while read in original in the tandem course, Sanskrit 214.\n\n	Indian Studies 207a	\N
36	Archaic Indian Religion: The Vedas	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Overview of the oldest form of Indian religion, in the Vedic texts (c. 1500bc-500bce): the mythological system of the Rgveda, the complex array of solemn srauta and domestic rituals (rites of passage), and the transcendental philosophy of the Upanisads. Stresses the coherent Weltanschauung underlying all aspects of Vedic thought.\n	Indian Studies 211	\N
37	Advanced Poetic Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Texts by Kashmiri authors.	Sanskrit 200ar	\N
38	Ritual Sutras	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Reading and discussion of Sutras and Paddhatis. Selection for 2000-01: Agnihotra, Homa and Puja texts from the Vedas, Puranas, Tantras.	Sanskrit 214	\N
39	Elementary Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3		Sanskrit 101a	\N
40	Intermediate Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3		Sanskrit 102a	\N
41	Philosophical Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3		Sanskrit 201br	\N
\.
--
-- Data for TOC Entry ID 56 (OID 82817)
--
-- Name: course Type: TABLE DATA Owner: postgres
--


COPY "course" FROM stdin;
8	Introduction to Classical Sanskrit	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 340	A course intended to provide a working knowledge of Sanskrit grammar and the ability to read simple texts in Sanskrit. Primarily (but not solely) intended for advancing students in Buddhist and Hindu studies.
9	Studies in Hinduism	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 311	In this course we will be examining the sources and manifestations of feminine power in Hinduism. Whereas in Christianity, Islam, and Judaism the divine is predominantly spoken of in masculine terms, in Hinduism divinity is imagined as either being male or female (and sometimes even beyond male and female). In Hinduism the creator of the universe can thus be referred to as Goddess (devi) or "Mother" (mata) rather than God or "Father". We will be looking at the impact the idea of a feminine source of creation and destruction has on the religious imagination of culture. How do women and men relate to the divine feminine? What are the different forms that the divine feminine assumes? How is the Goddess perceived and spoken of in sacred texts, ancient and contemporary? What are some of the narratives, rituals, icons, and religious meanings involved in her worship?
10	Sex, Death and Salvation in Asian Religions	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 104	Sex and death are inseparably intertwined in the two major religions of Asia, Buddhism and Hinduism. Sex makes the world of death and rebirth go round, and this is a problem for humans, who normally wish to avoid death and live forever. In this course, we explore how Buddhism and Hinduism construe this problem, and the many ways they seek to resolve it: by renouncing, sublimating, or embracing sex and the world that it perpetuates. Topics covered include the theory of karma and rebirth (reincarnation), Hindu and Buddhist monasticism, cosmology and cosmography, death rituals, ghosts and exorcism, religious eroticism, and tantric sex.
18	Religions of India	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 228	This course focuses on introducing the various ideas and practices that make up Hinduism, while paying some attention to Jainism and Sikhism. In particular we will be looking at the cultural and historical conditions in which these religious traditions emerged and evolved. We will explore the multi-dimensional inter-connections between religious ideas, myth, art, music, architecture, ritual, narritive, social structure, politics and philosophy in a historical and contemporary perspective. Where possible, lectures will be supplemented by viewing relevent video documentation. The intention of the course is to provide a well-grounded overview of Indian religions and a foundation for further study.
24	Introduction to Hinduism	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1600	This course will attempt an Introduction to Hinduism(s) by a reading of some of the texts that have gained prominence amongst Hindus over the centuries. Readings will include extracts from the ancient Vedas, the philosophical Upanisads, the Dharma law books, psycho-meditational texts such as the Yoga Sutras, the Ramayana and Mahabharata epics, the famous Bhagavad Gita, the Siva Purana, the Devi Gita of the Goddess, devotional poetry, and modern religious writings that have become authoritative texts amongst various present-day religious groups.\n
25	The Bhagavad Gita	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1614	The Bhagavad Gita is one of the best-known texts of the Hindu tradition. Incorporating elements from the oldest Vedas, concepts from the Upanishads, and features from the classical schools of Yoga, Sankhya, and Vedanta, the text serves as a base to overview much that has come to be known as Hinduism. Reading of the entire text, with special attention to a wide variety of different commentaries, ancient and modern. Consideration of the role of the text in European Romanticism, Indian nationalism, and Western neo-Hindu religious movements.\n
27	Yoga and Ancient Indian Systems of Liberation	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1617	This course will consist of a close reading of Patanjalis Yoga Sutras, the earliest comprehensive manual on yoga psychology and meditation in ancient India. Further readings will include classical soteriological texts from different schools that have appropriated such meditational techniques as a means towards their various goals of liberation. These will include both monistic and theistic Hindu schools such as Kashmir Saivism, Vaishnava bhakti and Tantric Shakta schools, as well as Buddhist practices. Additional readings will examine the systems of some of the more prominent practitioners of yoga in the modern period to consider issues of innovation and continuity.
28	Readings in Hindu Myth, Image, and Pilgrimage	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 3601	Intensive reading and research on specific topics in Hindu mythology, image and iconography, temples and temple towns, sacred geography and pilgrimage patterns.
33	Introduction to Vedic Sanskrit and Literature	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 204ar	Introduction to Vedic grammar. Selection of Vedic prose texts from the Yajurveda Samhitas, Brahmanas, Aranyakas and Upanisads. Builds on knowledge of elementary Sanskrit or Old Iranian.\n
36	Archaic Indian Religion: The Vedas	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Indian Studies 211	Overview of the oldest form of Indian religion, in the Vedic texts (c. 1500bc-500bce): the mythological system of the Rgveda, the complex array of solemn srauta and domestic rituals (rites of passage), and the transcendental philosophy of the Upanisads. Stresses the coherent Weltanschauung underlying all aspects of Vedic thought.\n
37	Advanced Poetic Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 200ar	Texts by Kashmiri authors.
38	Ritual Sutras	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 214	Reading and discussion of Sutras and Paddhatis. Selection for 2000-01: Agnihotra, Homa and Puja texts from the Vedas, Puranas, Tantras.
39	Elementary Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 101a	
40	Intermediate Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 102a	
41	Philosophical Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 201br	
35	Understanding Indian Ritual	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Indian Studies 207a	Investigates the indigenous theory and practice of Indian ritual, from its beginnings in the second millennium BCE (Rgveda) to present time. Stress on the development of the Agnihotra and Homa and Puja rituals, with materials from Vedic, Puranic, Tantric, and Buddhist sources, including their use in Bali, Tibet and Japan, and audio-vidual materials. Recent theories of ritual will also be discussed. Sanskrit texts are used in translation, while read in original in the tandem course, Sanskrit 214.\n\n
45	Hinduism	http://www.bu.edu/religion/courses/coursespage/courses-new.html	4	RN 213	Introduction to the Hindu tradition. Ritual and philosophy of the Vedas and Upanishads, yoga in the Bhagavad Gita, gods and goddesses in Hindu mythology, "popular" aspects of village and temple ritual, and problems of modernization and communalism in postcolonial India.
\.
--
-- Data for TOC Entry ID 57 (OID 82839)
--
-- Name: temp_course1494 Type: TABLE DATA Owner: postgres
--


COPY "temp_course1494" FROM stdin;
8	Introduction to Classical Sanskrit	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 340	A course intended to provide a working knowledge of Sanskrit grammar and the ability to read simple texts in Sanskrit. Primarily (but not solely) intended for advancing students in Buddhist and Hindu studies.
9	Studies in Hinduism	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 311	In this course we will be examining the sources and manifestations of feminine power in Hinduism. Whereas in Christianity, Islam, and Judaism the divine is predominantly spoken of in masculine terms, in Hinduism divinity is imagined as either being male or female (and sometimes even beyond male and female). In Hinduism the creator of the universe can thus be referred to as Goddess (devi) or "Mother" (mata) rather than God or "Father". We will be looking at the impact the idea of a feminine source of creation and destruction has on the religious imagination of culture. How do women and men relate to the divine feminine? What are the different forms that the divine feminine assumes? How is the Goddess perceived and spoken of in sacred texts, ancient and contemporary? What are some of the narratives, rituals, icons, and religious meanings involved in her worship?
10	Sex, Death and Salvation in Asian Religions	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 104	Sex and death are inseparably intertwined in the two major religions of Asia, Buddhism and Hinduism. Sex makes the world of death and rebirth go round, and this is a problem for humans, who normally wish to avoid death and live forever. In this course, we explore how Buddhism and Hinduism construe this problem, and the many ways they seek to resolve it: by renouncing, sublimating, or embracing sex and the world that it perpetuates. Topics covered include the theory of karma and rebirth (reincarnation), Hindu and Buddhist monasticism, cosmology and cosmography, death rituals, ghosts and exorcism, religious eroticism, and tantric sex.
18	Religions of India	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 228	This course focuses on introducing the various ideas and practices that make up Hinduism, while paying some attention to Jainism and Sikhism. In particular we will be looking at the cultural and historical conditions in which these religious traditions emerged and evolved. We will explore the multi-dimensional inter-connections between religious ideas, myth, art, music, architecture, ritual, narritive, social structure, politics and philosophy in a historical and contemporary perspective. Where possible, lectures will be supplemented by viewing relevent video documentation. The intention of the course is to provide a well-grounded overview of Indian religions and a foundation for further study.
24	Introduction to Hinduism	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1600	This course will attempt an Introduction to Hinduism(s) by a reading of some of the texts that have gained prominence amongst Hindus over the centuries. Readings will include extracts from the ancient Vedas, the philosophical Upanisads, the Dharma law books, psycho-meditational texts such as the Yoga Sutras, the Ramayana and Mahabharata epics, the famous Bhagavad Gita, the Siva Purana, the Devi Gita of the Goddess, devotional poetry, and modern religious writings that have become authoritative texts amongst various present-day religious groups.\n
25	The Bhagavad Gita	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1614	The Bhagavad Gita is one of the best-known texts of the Hindu tradition. Incorporating elements from the oldest Vedas, concepts from the Upanishads, and features from the classical schools of Yoga, Sankhya, and Vedanta, the text serves as a base to overview much that has come to be known as Hinduism. Reading of the entire text, with special attention to a wide variety of different commentaries, ancient and modern. Consideration of the role of the text in European Romanticism, Indian nationalism, and Western neo-Hindu religious movements.\n
27	Yoga and Ancient Indian Systems of Liberation	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1617	This course will consist of a close reading of Patanjalis Yoga Sutras, the earliest comprehensive manual on yoga psychology and meditation in ancient India. Further readings will include classical soteriological texts from different schools that have appropriated such meditational techniques as a means towards their various goals of liberation. These will include both monistic and theistic Hindu schools such as Kashmir Saivism, Vaishnava bhakti and Tantric Shakta schools, as well as Buddhist practices. Additional readings will examine the systems of some of the more prominent practitioners of yoga in the modern period to consider issues of innovation and continuity.
28	Readings in Hindu Myth, Image, and Pilgrimage	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 3601	Intensive reading and research on specific topics in Hindu mythology, image and iconography, temples and temple towns, sacred geography and pilgrimage patterns.
33	Introduction to Vedic Sanskrit and Literature	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 204ar	Introduction to Vedic grammar. Selection of Vedic prose texts from the Yajurveda Samhitas, Brahmanas, Aranyakas and Upanisads. Builds on knowledge of elementary Sanskrit or Old Iranian.\n
36	Archaic Indian Religion: The Vedas	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Indian Studies 211	Overview of the oldest form of Indian religion, in the Vedic texts (c. 1500bc-500bce): the mythological system of the Rgveda, the complex array of solemn srauta and domestic rituals (rites of passage), and the transcendental philosophy of the Upanisads. Stresses the coherent Weltanschauung underlying all aspects of Vedic thought.\n
37	Advanced Poetic Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 200ar	Texts by Kashmiri authors.
38	Ritual Sutras	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 214	Reading and discussion of Sutras and Paddhatis. Selection for 2000-01: Agnihotra, Homa and Puja texts from the Vedas, Puranas, Tantras.
39	Elementary Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 101a	
40	Intermediate Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 102a	
41	Philosophical Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 201br	
35	Understanding Indian Ritual	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Indian Studies 207a	Investigates the indigenous theory and practice of Indian ritual, from its beginnings in the second millennium BCE (Rgveda) to present time. Stress on the development of the Agnihotra and Homa and Puja rituals, with materials from Vedic, Puranic, Tantric, and Buddhist sources, including their use in Bali, Tibet and Japan, and audio-vidual materials. Recent theories of ritual will also be discussed. Sanskrit texts are used in translation, while read in original in the tandem course, Sanskrit 214.\n\n
\.
--
-- Data for TOC Entry ID 58 (OID 82861)
--
-- Name: temp_course1498 Type: TABLE DATA Owner: postgres
--


COPY "temp_course1498" FROM stdin;
8	Introduction to Classical Sanskrit	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 340	A course intended to provide a working knowledge of Sanskrit grammar and the ability to read simple texts in Sanskrit. Primarily (but not solely) intended for advancing students in Buddhist and Hindu studies.
9	Studies in Hinduism	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 311	In this course we will be examining the sources and manifestations of feminine power in Hinduism. Whereas in Christianity, Islam, and Judaism the divine is predominantly spoken of in masculine terms, in Hinduism divinity is imagined as either being male or female (and sometimes even beyond male and female). In Hinduism the creator of the universe can thus be referred to as Goddess (devi) or "Mother" (mata) rather than God or "Father". We will be looking at the impact the idea of a feminine source of creation and destruction has on the religious imagination of culture. How do women and men relate to the divine feminine? What are the different forms that the divine feminine assumes? How is the Goddess perceived and spoken of in sacred texts, ancient and contemporary? What are some of the narratives, rituals, icons, and religious meanings involved in her worship?
10	Sex, Death and Salvation in Asian Religions	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 104	Sex and death are inseparably intertwined in the two major religions of Asia, Buddhism and Hinduism. Sex makes the world of death and rebirth go round, and this is a problem for humans, who normally wish to avoid death and live forever. In this course, we explore how Buddhism and Hinduism construe this problem, and the many ways they seek to resolve it: by renouncing, sublimating, or embracing sex and the world that it perpetuates. Topics covered include the theory of karma and rebirth (reincarnation), Hindu and Buddhist monasticism, cosmology and cosmography, death rituals, ghosts and exorcism, religious eroticism, and tantric sex.
18	Religions of India	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 228	This course focuses on introducing the various ideas and practices that make up Hinduism, while paying some attention to Jainism and Sikhism. In particular we will be looking at the cultural and historical conditions in which these religious traditions emerged and evolved. We will explore the multi-dimensional inter-connections between religious ideas, myth, art, music, architecture, ritual, narritive, social structure, politics and philosophy in a historical and contemporary perspective. Where possible, lectures will be supplemented by viewing relevent video documentation. The intention of the course is to provide a well-grounded overview of Indian religions and a foundation for further study.
24	Introduction to Hinduism	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1600	This course will attempt an Introduction to Hinduism(s) by a reading of some of the texts that have gained prominence amongst Hindus over the centuries. Readings will include extracts from the ancient Vedas, the philosophical Upanisads, the Dharma law books, psycho-meditational texts such as the Yoga Sutras, the Ramayana and Mahabharata epics, the famous Bhagavad Gita, the Siva Purana, the Devi Gita of the Goddess, devotional poetry, and modern religious writings that have become authoritative texts amongst various present-day religious groups.\n
25	The Bhagavad Gita	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1614	The Bhagavad Gita is one of the best-known texts of the Hindu tradition. Incorporating elements from the oldest Vedas, concepts from the Upanishads, and features from the classical schools of Yoga, Sankhya, and Vedanta, the text serves as a base to overview much that has come to be known as Hinduism. Reading of the entire text, with special attention to a wide variety of different commentaries, ancient and modern. Consideration of the role of the text in European Romanticism, Indian nationalism, and Western neo-Hindu religious movements.\n
27	Yoga and Ancient Indian Systems of Liberation	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1617	This course will consist of a close reading of Patanjalis Yoga Sutras, the earliest comprehensive manual on yoga psychology and meditation in ancient India. Further readings will include classical soteriological texts from different schools that have appropriated such meditational techniques as a means towards their various goals of liberation. These will include both monistic and theistic Hindu schools such as Kashmir Saivism, Vaishnava bhakti and Tantric Shakta schools, as well as Buddhist practices. Additional readings will examine the systems of some of the more prominent practitioners of yoga in the modern period to consider issues of innovation and continuity.
28	Readings in Hindu Myth, Image, and Pilgrimage	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 3601	Intensive reading and research on specific topics in Hindu mythology, image and iconography, temples and temple towns, sacred geography and pilgrimage patterns.
33	Introduction to Vedic Sanskrit and Literature	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 204ar	Introduction to Vedic grammar. Selection of Vedic prose texts from the Yajurveda Samhitas, Brahmanas, Aranyakas and Upanisads. Builds on knowledge of elementary Sanskrit or Old Iranian.\n
36	Archaic Indian Religion: The Vedas	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Indian Studies 211	Overview of the oldest form of Indian religion, in the Vedic texts (c. 1500bc-500bce): the mythological system of the Rgveda, the complex array of solemn srauta and domestic rituals (rites of passage), and the transcendental philosophy of the Upanisads. Stresses the coherent Weltanschauung underlying all aspects of Vedic thought.\n
37	Advanced Poetic Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 200ar	Texts by Kashmiri authors.
38	Ritual Sutras	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 214	Reading and discussion of Sutras and Paddhatis. Selection for 2000-01: Agnihotra, Homa and Puja texts from the Vedas, Puranas, Tantras.
39	Elementary Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 101a	
40	Intermediate Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 102a	
41	Philosophical Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 201br	
35	Understanding Indian Ritual	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Indian Studies 207a	Investigates the indigenous theory and practice of Indian ritual, from its beginnings in the second millennium BCE (Rgveda) to present time. Stress on the development of the Agnihotra and Homa and Puja rituals, with materials from Vedic, Puranic, Tantric, and Buddhist sources, including their use in Bali, Tibet and Japan, and audio-vidual materials. Recent theories of ritual will also be discussed. Sanskrit texts are used in translation, while read in original in the tandem course, Sanskrit 214.\n\n
\.
--
-- Data for TOC Entry ID 59 (OID 82883)
--
-- Name: temp_course1500 Type: TABLE DATA Owner: postgres
--


COPY "temp_course1500" FROM stdin;
8	Introduction to Classical Sanskrit	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 340	A course intended to provide a working knowledge of Sanskrit grammar and the ability to read simple texts in Sanskrit. Primarily (but not solely) intended for advancing students in Buddhist and Hindu studies.
9	Studies in Hinduism	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 311	In this course we will be examining the sources and manifestations of feminine power in Hinduism. Whereas in Christianity, Islam, and Judaism the divine is predominantly spoken of in masculine terms, in Hinduism divinity is imagined as either being male or female (and sometimes even beyond male and female). In Hinduism the creator of the universe can thus be referred to as Goddess (devi) or "Mother" (mata) rather than God or "Father". We will be looking at the impact the idea of a feminine source of creation and destruction has on the religious imagination of culture. How do women and men relate to the divine feminine? What are the different forms that the divine feminine assumes? How is the Goddess perceived and spoken of in sacred texts, ancient and contemporary? What are some of the narratives, rituals, icons, and religious meanings involved in her worship?
10	Sex, Death and Salvation in Asian Religions	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 104	Sex and death are inseparably intertwined in the two major religions of Asia, Buddhism and Hinduism. Sex makes the world of death and rebirth go round, and this is a problem for humans, who normally wish to avoid death and live forever. In this course, we explore how Buddhism and Hinduism construe this problem, and the many ways they seek to resolve it: by renouncing, sublimating, or embracing sex and the world that it perpetuates. Topics covered include the theory of karma and rebirth (reincarnation), Hindu and Buddhist monasticism, cosmology and cosmography, death rituals, ghosts and exorcism, religious eroticism, and tantric sex.
18	Religions of India	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 228	This course focuses on introducing the various ideas and practices that make up Hinduism, while paying some attention to Jainism and Sikhism. In particular we will be looking at the cultural and historical conditions in which these religious traditions emerged and evolved. We will explore the multi-dimensional inter-connections between religious ideas, myth, art, music, architecture, ritual, narritive, social structure, politics and philosophy in a historical and contemporary perspective. Where possible, lectures will be supplemented by viewing relevent video documentation. The intention of the course is to provide a well-grounded overview of Indian religions and a foundation for further study.
24	Introduction to Hinduism	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1600	This course will attempt an Introduction to Hinduism(s) by a reading of some of the texts that have gained prominence amongst Hindus over the centuries. Readings will include extracts from the ancient Vedas, the philosophical Upanisads, the Dharma law books, psycho-meditational texts such as the Yoga Sutras, the Ramayana and Mahabharata epics, the famous Bhagavad Gita, the Siva Purana, the Devi Gita of the Goddess, devotional poetry, and modern religious writings that have become authoritative texts amongst various present-day religious groups.\n
25	The Bhagavad Gita	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1614	The Bhagavad Gita is one of the best-known texts of the Hindu tradition. Incorporating elements from the oldest Vedas, concepts from the Upanishads, and features from the classical schools of Yoga, Sankhya, and Vedanta, the text serves as a base to overview much that has come to be known as Hinduism. Reading of the entire text, with special attention to a wide variety of different commentaries, ancient and modern. Consideration of the role of the text in European Romanticism, Indian nationalism, and Western neo-Hindu religious movements.\n
27	Yoga and Ancient Indian Systems of Liberation	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1617	This course will consist of a close reading of Patanjalis Yoga Sutras, the earliest comprehensive manual on yoga psychology and meditation in ancient India. Further readings will include classical soteriological texts from different schools that have appropriated such meditational techniques as a means towards their various goals of liberation. These will include both monistic and theistic Hindu schools such as Kashmir Saivism, Vaishnava bhakti and Tantric Shakta schools, as well as Buddhist practices. Additional readings will examine the systems of some of the more prominent practitioners of yoga in the modern period to consider issues of innovation and continuity.
28	Readings in Hindu Myth, Image, and Pilgrimage	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 3601	Intensive reading and research on specific topics in Hindu mythology, image and iconography, temples and temple towns, sacred geography and pilgrimage patterns.
33	Introduction to Vedic Sanskrit and Literature	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 204ar	Introduction to Vedic grammar. Selection of Vedic prose texts from the Yajurveda Samhitas, Brahmanas, Aranyakas and Upanisads. Builds on knowledge of elementary Sanskrit or Old Iranian.\n
36	Archaic Indian Religion: The Vedas	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Indian Studies 211	Overview of the oldest form of Indian religion, in the Vedic texts (c. 1500bc-500bce): the mythological system of the Rgveda, the complex array of solemn srauta and domestic rituals (rites of passage), and the transcendental philosophy of the Upanisads. Stresses the coherent Weltanschauung underlying all aspects of Vedic thought.\n
37	Advanced Poetic Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 200ar	Texts by Kashmiri authors.
38	Ritual Sutras	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 214	Reading and discussion of Sutras and Paddhatis. Selection for 2000-01: Agnihotra, Homa and Puja texts from the Vedas, Puranas, Tantras.
39	Elementary Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 101a	
40	Intermediate Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 102a	
41	Philosophical Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 201br	
35	Understanding Indian Ritual	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Indian Studies 207a	Investigates the indigenous theory and practice of Indian ritual, from its beginnings in the second millennium BCE (Rgveda) to present time. Stress on the development of the Agnihotra and Homa and Puja rituals, with materials from Vedic, Puranic, Tantric, and Buddhist sources, including their use in Bali, Tibet and Japan, and audio-vidual materials. Recent theories of ritual will also be discussed. Sanskrit texts are used in translation, while read in original in the tandem course, Sanskrit 214.\n\n
\.
--
-- Data for TOC Entry ID 60 (OID 82905)
--
-- Name: temp_course1502 Type: TABLE DATA Owner: postgres
--


COPY "temp_course1502" FROM stdin;
8	Introduction to Classical Sanskrit	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 340	A course intended to provide a working knowledge of Sanskrit grammar and the ability to read simple texts in Sanskrit. Primarily (but not solely) intended for advancing students in Buddhist and Hindu studies.
9	Studies in Hinduism	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 311	In this course we will be examining the sources and manifestations of feminine power in Hinduism. Whereas in Christianity, Islam, and Judaism the divine is predominantly spoken of in masculine terms, in Hinduism divinity is imagined as either being male or female (and sometimes even beyond male and female). In Hinduism the creator of the universe can thus be referred to as Goddess (devi) or "Mother" (mata) rather than God or "Father". We will be looking at the impact the idea of a feminine source of creation and destruction has on the religious imagination of culture. How do women and men relate to the divine feminine? What are the different forms that the divine feminine assumes? How is the Goddess perceived and spoken of in sacred texts, ancient and contemporary? What are some of the narratives, rituals, icons, and religious meanings involved in her worship?
10	Sex, Death and Salvation in Asian Religions	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 104	Sex and death are inseparably intertwined in the two major religions of Asia, Buddhism and Hinduism. Sex makes the world of death and rebirth go round, and this is a problem for humans, who normally wish to avoid death and live forever. In this course, we explore how Buddhism and Hinduism construe this problem, and the many ways they seek to resolve it: by renouncing, sublimating, or embracing sex and the world that it perpetuates. Topics covered include the theory of karma and rebirth (reincarnation), Hindu and Buddhist monasticism, cosmology and cosmography, death rituals, ghosts and exorcism, religious eroticism, and tantric sex.
18	Religions of India	http://www.rels.canterbury.ac.nz/pages/hindu.html	1	RELS 228	This course focuses on introducing the various ideas and practices that make up Hinduism, while paying some attention to Jainism and Sikhism. In particular we will be looking at the cultural and historical conditions in which these religious traditions emerged and evolved. We will explore the multi-dimensional inter-connections between religious ideas, myth, art, music, architecture, ritual, narritive, social structure, politics and philosophy in a historical and contemporary perspective. Where possible, lectures will be supplemented by viewing relevent video documentation. The intention of the course is to provide a well-grounded overview of Indian religions and a foundation for further study.
24	Introduction to Hinduism	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1600	This course will attempt an Introduction to Hinduism(s) by a reading of some of the texts that have gained prominence amongst Hindus over the centuries. Readings will include extracts from the ancient Vedas, the philosophical Upanisads, the Dharma law books, psycho-meditational texts such as the Yoga Sutras, the Ramayana and Mahabharata epics, the famous Bhagavad Gita, the Siva Purana, the Devi Gita of the Goddess, devotional poetry, and modern religious writings that have become authoritative texts amongst various present-day religious groups.\n
25	The Bhagavad Gita	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1614	The Bhagavad Gita is one of the best-known texts of the Hindu tradition. Incorporating elements from the oldest Vedas, concepts from the Upanishads, and features from the classical schools of Yoga, Sankhya, and Vedanta, the text serves as a base to overview much that has come to be known as Hinduism. Reading of the entire text, with special attention to a wide variety of different commentaries, ancient and modern. Consideration of the role of the text in European Romanticism, Indian nationalism, and Western neo-Hindu religious movements.\n
27	Yoga and Ancient Indian Systems of Liberation	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 1617	This course will consist of a close reading of Patanjalis Yoga Sutras, the earliest comprehensive manual on yoga psychology and meditation in ancient India. Further readings will include classical soteriological texts from different schools that have appropriated such meditational techniques as a means towards their various goals of liberation. These will include both monistic and theistic Hindu schools such as Kashmir Saivism, Vaishnava bhakti and Tantric Shakta schools, as well as Buddhist practices. Additional readings will examine the systems of some of the more prominent practitioners of yoga in the modern period to consider issues of innovation and continuity.
28	Readings in Hindu Myth, Image, and Pilgrimage	http://www.hds.harvard.edu/cswr/courselist/hinduism.htm	3	Religion 3601	Intensive reading and research on specific topics in Hindu mythology, image and iconography, temples and temple towns, sacred geography and pilgrimage patterns.
33	Introduction to Vedic Sanskrit and Literature	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 204ar	Introduction to Vedic grammar. Selection of Vedic prose texts from the Yajurveda Samhitas, Brahmanas, Aranyakas and Upanisads. Builds on knowledge of elementary Sanskrit or Old Iranian.\n
36	Archaic Indian Religion: The Vedas	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Indian Studies 211	Overview of the oldest form of Indian religion, in the Vedic texts (c. 1500bc-500bce): the mythological system of the Rgveda, the complex array of solemn srauta and domestic rituals (rites of passage), and the transcendental philosophy of the Upanisads. Stresses the coherent Weltanschauung underlying all aspects of Vedic thought.\n
37	Advanced Poetic Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 200ar	Texts by Kashmiri authors.
38	Ritual Sutras	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 214	Reading and discussion of Sutras and Paddhatis. Selection for 2000-01: Agnihotra, Homa and Puja texts from the Vedas, Puranas, Tantras.
39	Elementary Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 101a	
40	Intermediate Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 102a	
41	Philosophical Sanskrit	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	2	Sanskrit 201br	
35	Understanding Indian Ritual	http://www.registrar.fas.harvard.edu/Courses/SanskritandIndianStudies.html	3	Indian Studies 207a	Investigates the indigenous theory and practice of Indian ritual, from its beginnings in the second millennium BCE (Rgveda) to present time. Stress on the development of the Agnihotra and Homa and Puja rituals, with materials from Vedic, Puranic, Tantric, and Buddhist sources, including their use in Bali, Tibet and Japan, and audio-vidual materials. Recent theories of ritual will also be discussed. Sanskrit texts are used in translation, while read in original in the tandem course, Sanskrit 214.\n\n
\.
--
-- TOC Entry ID 40 (OID 66538)
--
-- Name: "publisher_pkey" Type: INDEX Owner: postgres
--

CREATE UNIQUE INDEX publisher_pkey ON publisher USING btree (id, name);

--
-- TOC Entry ID 41 (OID 66541)
--
-- Name: "material_type_pkey" Type: INDEX Owner: postgres
--

CREATE UNIQUE INDEX material_type_pkey ON material_type USING btree (id, name);

--
-- TOC Entry ID 42 (OID 66613)
--
-- Name: "course_material_pkey" Type: INDEX Owner: postgres
--

CREATE UNIQUE INDEX course_material_pkey ON course_material USING btree (course_id, material_type_id, material_id);

--
-- TOC Entry ID 3 (OID 66404)
--
-- Name: school___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"school___id"', 6, true);

--
-- TOC Entry ID 5 (OID 66412)
--
-- Name: material_type___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"material_type___id"', 25, true);

--
-- TOC Entry ID 7 (OID 66420)
--
-- Name: course___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"course___id"', 45, true);

--
-- TOC Entry ID 9 (OID 66428)
--
-- Name: book___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"book___id"', 15, true);

--
-- TOC Entry ID 11 (OID 66436)
--
-- Name: publisher___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"publisher___id"', 18, true);

--
-- TOC Entry ID 13 (OID 66444)
--
-- Name: person_type___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"person_type___id"', 4, true);

--
-- TOC Entry ID 15 (OID 66446)
--
-- Name: person___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"person___id"', 10, true);

--
-- TOC Entry ID 17 (OID 66457)
--
-- Name: personperson_type___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"personperson_type___id"', 2, true);

--
-- TOC Entry ID 19 (OID 66550)
--
-- Name: course_reader___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"course_reader___id"', 18, true);

--
-- TOC Entry ID 21 (OID 74536)
--
-- Name: dept___id Type: SEQUENCE SET Owner: postgres
--

SELECT setval ('"dept___id"', 4, true);


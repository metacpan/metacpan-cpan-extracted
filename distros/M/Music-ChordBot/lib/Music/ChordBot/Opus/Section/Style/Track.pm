#! perl

use strict;
use warnings;
use utf8;

package Music::ChordBot::Opus::Section::Style::Track;

=head1 NAME

Music::ChordBot::Opus::Section::Style- ChordBot styles.

=cut

our $VERSION = 0.01;

use parent 'Music::ChordBot::Opus::Base';

=head1 SYNOPSIS

    use Music::ChordBot::Opus::Section::Style::Track;
    $track = Music::ChordBot::Section::Style::Track->new;
    $track->id(14)->volume(6);

=head1 METHODS

=head2 new [ I<args> ]

Creates a new Music::ChordBot::Opus::Section::Style::Track object.

Initial attributes can be passed to the constructor as a hash.

Attributes:

=over 4

=item id

The track id. The id selects an instrument and comping pattern.

=item volume

The desired volume.

=back

=cut

sub new {
    my $pkg = shift;
    my $data = { @_ };
    bless { data => $data }, $pkg;
}

=head2 id volume

Accessors can be used to set and/or get these attributes.

=cut

sub id     { shift->_setget( "id",     @_ ) }
sub volume { shift->_setget( "volume", @_ ) }

=head2 instrument

Returns a string describing the instrument for the current track.

=cut

sub instrument { $_[0]->description->{instrument} }

=head2 pattern

Returns a string describing the pattern for the current track.

=cut

sub pattern    { $_[0]->description->{pattern}    }

my @descriptions;
sub description {
    my ( $self, $id ) = @_;
    $id //= $self->id;

    unless ( @descriptions ) {
	my $data = <<EOD;
1	Synth	Arp 01
2	Synth	Arp 02
3	Synth	Arp 03
4	Synth	Arp 04
5	Synth	Arp 05
6	Synth	Arp 06
7	Synth	Arp 07
8	Synth	Arp 08
9	Synth	Arp 09
10	Synth	Arp 10
11	Synth	Arp 11
12	Synth	Arp 12
13	Piano	Arpeggio 01
14	Piano	Arpeggio 02
15	Piano	Arpeggio 03
16	Piano	Arpeggio 04
17	Piano	Arpeggio 05
18	Piano	Arpeggio 06
19	Piano	Arpeggio 07
20	Piano	Arpeggio 08
21	Piano	Arpeggio 09
22	Piano	Arpeggio 10
23	Piano	Arpeggio 11
24	Piano	Arpeggio 12
25	Piano	Arpeggio 13
26	Piano	Arpeggio 14
27	Piano	Arpeggio 15
28	Piano	Arpeggio 16
29	Piano	Arpeggio 17
30	Piano	Arpeggio 18
31	Piano	Arpeggio 19
32	Piano	Arpeggio 20
33	Piano	Arpeggio 21
34	Piano	Arpeggio 22
35	Piano	Arpeggio 23
36	Piano	Arpeggio 24
37	Piano	Arpeggio 25
38	Piano	Arpeggio 26
39	Piano	Arpeggio 27 - 6/8
40	Synth	Attack 01
41	Synth	Attack 02
42	Synth	Attack 03
43	Synth	Attack 04
44	Synth	Attack 05
45	Synth	Attack 06
46	Synth	Attack 07
47	Synth	Bass 01
48	Synth	Bass 02
49	Synth	Bass 03
50	Synth	Bass 04
51	Synth	Bass 05
52	Synth	Bass 06
53	Synth	Bass 07
54	Drums	Electro 01
55	Drums	Electro 02
56	Drums	Electro 03
57	Drums	Electro 04
58	Drums	Electro 05
59	Drums	Electro 06
60	Drums	Electro 07
61	Drums	Electro 08
62	Drums	Electro 09
63	Drums	Electro 10
64	Drums	Electro 11
65	Drums	Electro 12
66	Keyboard	FM 01
67	Keyboard	FM 02
68	Keyboard	FM 03
69	Keyboard	FM 04
70	Keyboard	FM 05
71	Keyboard	FM 06
72	Keyboard	FM 07
73	Keyboard	FM 08
74	Keyboard	FM 09
75	Keyboard	FM 10
76	Keyboard	FM 11 - 3/4
77	Keyboard	FM 12
78	Keyboard	FM 13
79	Keyboard	FM 14
80	Keyboard	FM 15
81	Keyboard	FM 16 - 6/8
82	Bass	Fifths 01
83	Bass	Fifths 02
84	Bass	Fifths 03
85	Bass	Fifths 04
86	Bass	Fifths 05
87	Bass	Fifths 06
88	Bass	Fifths 07
89	Bass	Fifths 08
90	Bass	Fifths 09
91	Piano	Hammered 01
92	Piano	Hammered 02
93	Piano	Hammered 03
94	Piano	Hammered 04
95	Piano	Hammered 05
96	Piano	Hammered 06
97	Piano	Hammered 07
98	Piano	Hammered 08
99	Piano	Hammered 09
100	Piano	Hammered 10
101	Piano	Hammered 11
102	Piano	Hammered 12
103	Piano	Hammered 13
104	Piano	Hammered 14
105	Piano	Hammered 15
106	Piano	Hammered 16
107	Piano	Hammered 17
108	Piano	Hammered 18
109	Piano	Hammered 19
110	Piano	Hammered 20
111	Piano	Hammered 21
112	Piano	Hammered 22
113	Piano	Hammered 23
114	Piano	Hammered 24
115	Piano	Hammered 25 - 5/4
116	Piano	Hammered 26 - 3/4
117	Piano	Hammered 27 - 3/4
118	Drums	Hard 01
119	Drums	Hard 02
120	Drums	Hard 03
121	Drums	Hard 04
122	Drums	Hard 05
123	Drums	Hard 06
124	Drums	Hard 07
125	Drums	Hard 08
126	Drums	Hard 09
127	Drums	Hard 10
128	Drums	Hard 11
129	Drums	Hard 12
130	Bass	Line 01
131	Bass	Line 02
132	Bass	Line 03
133	Bass	Line 04
134	Bass	Line 05
135	Bass	Line 06
136	Bass	Line 07
137	Bass	Line 08
138	Bass	Line 09
139	Bass	Line 10
140	Bass	Line 11
141	Drums	Medium 01
142	Drums	Medium 02
143	Drums	Medium 03
144	Drums	Medium 04
145	Drums	Medium 05
146	Drums	Medium 06
147	Drums	Medium 07
148	Drums	Medium 08
149	Drums	Medium 09
150	Drums	Medium 10
151	Drums	Medium 11
152	Drums	Medium 12
153	Drums	Metronome 2/4
154	Drums	Metronome 3/4
155	Drums	Metronome 4/4
156	Drums	Metronome 5/4
157	Drums	Metronome 6/8
158	E. Guitar	Muted 01
159	E. Guitar	Muted 02
160	E. Guitar	Muted 03
161	E. Guitar	Muted 04
162	E. Guitar	Muted 05
163	Bass	Octave 01
164	Bass	Octave 02
165	Bass	Octave 03
166	Bass	Octave 04
167	Bass	Octave 05
168	Bass	Octave 06
169	Bass	Octave 07
170	Bass	Octave 08
171	Bass	Octave 09
172	Keyboard	Organ 01
173	Keyboard	Organ 02
174	Keyboard	Organ 03
175	Keyboard	Organ 05
176	Keyboard	Organ 06
177	Keyboard	Organ 07
178	Keyboard	Organ 08
179	Keyboard	Organ 09
180	Keyboard	Organ 10
181	Keyboard	Organ 11
182	Keyboard	Organ 12
183	Keyboard	Organ 13
184	Keyboard	Organ 14
185	Keyboard	Organ 15
186	Keyboard	Organ Bass 01
187	Keyboard	Organ Bass 02
188	Drums	Percussion 01
189	Drums	Percussion 02
190	Drums	Percussion 03
191	Drums	Percussion 04
192	Drums	Percussion 05
193	Drums	Percussion 06
194	Drums	Percussion 07
195	Piano	Piano Bass 01
196	Piano	Piano Bass 02
197	Piano	Piano Bass 03
198	Piano	Piano Bass 04
199	Piano	Piano Bass 05
200	Piano	Piano Bass 06
201	Piano	Piano Bass 07
202	Piano	Piano Bass 08
203	Piano	Piano Bass 09
204	Piano	Piano Bass 10
205	Piano	Piano Bass 11
206	E. Guitar	Picked 01
207	A. Guitar	Picked 01
208	E. Guitar	Picked 02
209	A. Guitar	Picked 02
210	E. Guitar	Picked 03
211	A. Guitar	Picked 03
212	E. Guitar	Picked 04
213	A. Guitar	Picked 04
214	E. Guitar	Picked 05
215	A. Guitar	Picked 05
216	E. Guitar	Picked 06
217	A. Guitar	Picked 06 - 6/8
218	E. Guitar	Picked 07
219	A. Guitar	Picked 07
220	A. Guitar	Picked 08
221	E. Guitar	Picked 08 - 6/8
222	E. Guitar	Picked 09
223	A. Guitar	Picked 09
224	E. Guitar	Picked 10
225	A. Guitar	Picked 10
226	E. Guitar	Picked 11
227	A. Guitar	Picked 11
228	E. Guitar	Picked 12
229	A. Guitar	Picked 12
230	E. Guitar	Picked 13
231	A. Guitar	Picked 13
232	E. Guitar	Picked 14
233	A. Guitar	Picked 14
234	E. Guitar	Picked 15
235	A. Guitar	Picked 15
236	E. Guitar	Picked 16
237	A. Guitar	Picked 16
238	E. Guitar	Picked 17
239	A. Guitar	Picked 17
240	E. Guitar	Picked 18
241	A. Guitar	Picked 18
242	E. Guitar	Picked 19
243	A. Guitar	Picked 19
244	A. Guitar	Picked 20
245	A. Guitar	Picked 21
246	A. Guitar	Picked 22
247	A. Guitar	Picked 23
248	A. Guitar	Picked 24
249	Keyboard	Rhodes 01
250	Keyboard	Rhodes 02
251	Keyboard	Rhodes 03
252	Keyboard	Rhodes 04
253	Keyboard	Rhodes 05
254	Keyboard	Rhodes 06
255	Keyboard	Rhodes 07
256	Keyboard	Rhodes 08
257	Keyboard	Rhodes 09 - 3/4
258	Keyboard	Rhodes 10
259	Keyboard	Rhodes 11
260	Keyboard	Rhodes 12
261	Keyboard	Rhodes 13
262	Keyboard	Rhodes 14
263	Keyboard	Rhodes 15
264	Keyboard	Rhodes 16 - 6/8
265	Piano	Shuffle 01
266	Bass	Shuffle 01
267	Drums	Shuffle 01
268	Piano	Shuffle 02
269	Bass	Shuffle 02
270	Drums	Shuffle 02
271	Piano	Shuffle 03
272	Drums	Shuffle 03
273	Drums	Shuffle 04
274	Bass	Simple 01
275	Bass	Simple 02
276	Bass	Simple 03
277	Bass	Simple 04
278	Bass	Simple 05
279	Bass	Simple 06
280	Bass	Simple 07
281	Bass	Simple 08
282	Bass	Simple 09
283	Bass	Simple 10
284	Bass	Simple 11
285	Bass	Simple 12
286	Bass	Simple 13
287	Bass	Simple 14
288	Bass	Slap 01
289	Bass	Slap 02
290	Bass	Slap 03
291	Bass	Slap 04
292	Bass	Slap 05
293	Bass	Slap 06
294	Bass	Slap 07
295	Bass	Slap 08
296	Drums	Soft 01
297	Drums	Soft 02
298	Drums	Soft 03
299	Drums	Soft 04
300	Drums	Soft 05
301	Drums	Soft 06
302	Drums	Soft 07
303	Drums	Soft 08
304	Drums	Soft 09
305	Drums	Soft 10
306	Drums	Soft 11 - 3/4
307	Drums	Soft 12 - 6/8
308	E. Guitar	Stab 01
309	E. Guitar	Stab 02
310	E. Guitar	Stab 03
311	E. Guitar	Stab 04
312	Synth	Strings 01
313	Synth	Strings 02
314	Synth	Strings 03
315	Synth	Strings 04
316	E. Guitar	Strum 01
317	A. Guitar	Strum 01
318	E. Guitar	Strum 02
319	A. Guitar	Strum 02
320	E. Guitar	Strum 03
321	A. Guitar	Strum 03
322	E. Guitar	Strum 04
323	A. Guitar	Strum 04
324	E. Guitar	Strum 05
325	A. Guitar	Strum 05
326	E. Guitar	Strum 06
327	A. Guitar	Strum 06
328	E. Guitar	Strum 07
329	A. Guitar	Strum 07
330	E. Guitar	Strum 08
331	A. Guitar	Strum 08
332	E. Guitar	Strum 09
333	A. Guitar	Strum 09
334	E. Guitar	Strum 10
335	A. Guitar	Strum 10
336	E. Guitar	Strum 11
337	A. Guitar	Strum 11
338	E. Guitar	Strum 12
339	A. Guitar	Strum 12
340	E. Guitar	Strum 13
341	A. Guitar	Strum 13 - 3/4
342	E. Guitar	Strum 14
343	A. Guitar	Strum 14 - 3/4
344	E. Guitar	Strum 15
345	A. Guitar	Strum 15
346	E. Guitar	Strum 16
347	A. Guitar	Strum 16
348	E. Guitar	Strum 17
349	A. Guitar	Strum 17
350	E. Guitar	Strum 18
351	A. Guitar	Strum 18
352	E. Guitar	Strum 19
353	A. Guitar	Strum 19
354	E. Guitar	Strum 20
355	A. Guitar	Strum 20
356	E. Guitar	Strum 21
357	E. Guitar	Strum 22
358	E. Guitar	Strum 23
359	E. Guitar	Strum 24
360	E. Guitar	Strum 25
361	E. Guitar	Strum 26
362	E. Guitar	Strum 27 - 3/4
363	E. Guitar	Strum 28 - 3/4
364	Drums	Swing 01
365	Drums	Swing 02
366	Drums	Swing 03
367	Drums	Swing 04 - 3/4
368	Keyboard	Vibraphone 01
369	Keyboard	Vibraphone 02
370	Keyboard	Vibraphone 03
371	Keyboard	Vibraphone 04
372	Keyboard	Vibraphone 05
EOD
	for ( split( /\n/, $data ) ) {
	    my @a = split( /\t/, $_ );
	    push( @descriptions, { instrument => $a[1], pattern => $a[2] } );
	}
    }
    $descriptions[$id-1];
}

=head1 AUTHOR, COPYRIGHT & LICENSE

See L<Music::ChordBot>.

=cut

1;

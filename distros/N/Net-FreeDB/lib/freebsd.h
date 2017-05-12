 /*********************************************
NAME: freebsd.h
FUNCTION: FreeBSD based cddb id generation code
ORIGINALLY CREATED BY: David Shultz
ORIGINALLY CREATED ON: 08/03/2001
ADAPTED BY: Peter Pentchev
ADAPTED ON: 09/28/2005
*********************************************/
#ifndef FREEBSD_H
#define FREEBSD_H

struct discdata {
    unsigned long discid;
    int num_of_trks;
    int track_offsets[100];
    int seconds;
};

/*
 * The following has been blatantly stolen from FreeBSD 5.4's
 * cdcontrol(8) utility.
 */

int			msf;
struct cd_toc_entry	toc_buffer[100];

int read_toc_entrys (int fd, int len)
{
	struct ioc_read_toc_entry t;

	t.address_format = msf ? CD_MSF_FORMAT : CD_LBA_FORMAT;
	t.starting_track = 0;
	t.data_len = len;
	t.data = toc_buffer;

	return (ioctl (fd, CDIOREADTOCENTRYS, (char *) &t));
}

void lba2msf (unsigned long lba, u_char *m, u_char *s, u_char *f)
{
	lba += 150;			/* block start offset */
	lba &= 0xffffff;		/* negative lbas use only 24 bits */
	*m = lba / (60 * 75);
	lba %= (60 * 75);
	*s = lba / 75;
	*f = lba % 75;
}

/*
 * dbprog_sum
 *	Convert an integer to its text string representation, and
 *	compute its checksum.  Used by dbprog_discid to derive the
 *	disc ID.
 *
 * Args:
 *	n - The integer value.
 *
 * Return:
 *	The integer checksum.
 */
static int
dbprog_sum(int n)
{
	char	buf[12],
		*p;
	int	ret = 0;

	/* For backward compatibility this algorithm must not change */
	sprintf(buf, "%u", n);
	for (p = buf; *p != '\0'; p++)
		ret += (*p - '0');

	return(ret);
}

/*
 * dbprog_discid
 *	Compute a magic disc ID based on the number of tracks,
 *	the length of each track, and a checksum of the string
 *	that represents the offset of each track.
 *
 * Args:
 *	s - Pointer to the curstat_t structure.
 *
 * Return:
 *	The integer disc ID.
 */
int
dbprog_discid(int fd, struct discdata *d)
{
	struct	ioc_toc_header h;
	int	rc;
	int	i, ntr,
		t = 0,
		n = 0;
	long	block;
	u_char	m, s, f;

	rc = ioctl (fd, CDIOREADTOCHEADER, &h);
	if (rc < 0)
		return (0);
	ntr = h.ending_track - h.starting_track + 1;
	i = msf;
	msf = 1;
	rc = read_toc_entrys (fd, (ntr + 1) * sizeof (struct cd_toc_entry));
	msf = i;
	if (rc < 0)
		return (0);
	d->num_of_trks = ntr;

	/* For backward compatibility this algorithm must not change */
	d->track_offsets[0] = 150;
	for (i = 0; i < ntr; i++) {
#define TC_FR(a) toc_buffer[a].addr.msf.frame
#define TC_MM(a) toc_buffer[a].addr.msf.minute
#define TC_SS(a) toc_buffer[a].addr.msf.second
		n += dbprog_sum((TC_MM(i) * 60) + TC_SS(i));

		t += ((TC_MM(i+1) * 60) + TC_SS(i+1)) -
		    ((TC_MM(i) * 60) + TC_SS(i));

		d->track_offsets[i + 1] = TC_FR(i + 1) + TC_MM(i + 1) * 60 * 75 +
		    TC_SS(i+1)*75;
		fprintf(stderr, "i %d mm %d ss %d fr %d ofs %ld\n", i + 1, TC_MM(i + 1), TC_SS(i + 1), TC_FR(i + 1), d->track_offsets[i]);
	}

	d->discid = (n % 0xff) << 24 | t << 8 | ntr;
	/*
	block = ntohl(toc_buffer[ntr - 1].addr.lba);
	d->seconds = ((block + 150) & 0xfffff) / 75;
	*/
	d->seconds = TC_SS(ntr) + TC_MM(ntr) * 60;
	fprintf(stderr, "block is %ld, seconds are %ld\n", block, d->seconds);
	return (d->discid);
}

struct discdata
get_disc_id(const char *dev)
{
	int fd;
	struct discdata d;

	fd = open(dev, O_RDONLY | O_NONBLOCK);
	if (fd < 0) {
		memset(&d, 0, sizeof(d));
		return (d);
	}
	dbprog_discid(fd, &d);
	close(fd);
	return (d);
}

#endif //FREEBSD_H








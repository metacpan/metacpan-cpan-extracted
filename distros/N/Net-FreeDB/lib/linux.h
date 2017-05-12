 /*********************************************
NAME: linux.h
FUNCTION: linux based cddb id generation code
CREATED BY: David Shultz
CREATED ON: 08/03/2001
*********************************************/
#ifndef LINUX_H
#define LINUX_H

struct toc {
    int min, sec, frame;
} cdtoc[100];

struct discdata {
    unsigned long   discid;
    int             num_of_trks;
    int             track_offsets[100];
    int             seconds;
};

unsigned int cddb_sum(int n)
{
    unsigned int ret;

    ret = 0;
    while (n > 0) {
        ret += (n % 10);
        n /= 10;
    }
    return ret;
}

unsigned long cddb_discid(int tot_trks)
{
    unsigned int i = 0;
    unsigned int t = 0;
    unsigned int n = 0;

    while (i < tot_trks) {
        n = n + cddb_sum((cdtoc[i].min * 60) + cdtoc[i].sec);
        i++;
    }

    t = ((cdtoc[tot_trks].min * 60) + cdtoc[tot_trks].sec) -
        ((cdtoc[0].min * 60) + cdtoc[0].sec);
    return ((n % 0xff) << 24 | t << 8 | tot_trks);
}

struct discdata get_disc_id(char* dev)
{
    struct discdata data;
    int i;

    data.num_of_trks = read_toc(dev);

    if (data.num_of_trks == -1) {
        return data;
    }

    data.discid = cddb_discid(data.num_of_trks);

    for (i = 0; i < data.num_of_trks; i++) {
        data.track_offsets[i] = (cdtoc[i].frame);
    }

    data.seconds = (cdtoc[data.num_of_trks].frame)/75;

    return data;
}

int read_toc(char* dev)
{
    int drive, i, status;
    struct cdrom_tochdr tochdr;
    struct cdrom_tocentry tocentry;

    drive = open(dev, O_RDONLY | O_NONBLOCK);
    if (drive == -1) {
        printf("Device Error: %d\n", errno);
        return(-1);
    }

    status = ioctl(drive, CDROM_DRIVE_STATUS, CDSL_CURRENT);
    if (status < 0) {
        printf("Error: Error getting drive status\n");
        return(-1);
    } else {
        switch(status) {
            case CDS_DISC_OK:
                printf("Disc ok, moving on\n");
                break;
            case CDS_TRAY_OPEN:
                printf("Error: Drive reporting tray open...exiting\n");
                close(drive);
                return(-1);
            case CDS_DRIVE_NOT_READY:
                printf("Error: Drive Not Ready...exiting\n");
                close(drive);
                return(-1);
            default:
                printf("This shouldn't happen\n");
                close(drive);
                return(-1);
        }
    }

    if (ioctl(drive, CDROMREADTOCHDR, &tochdr) == -1) {
        switch(errno) {
            case EBADF:
                printf("Error: Invalid device...exiting\n");
                break;
            case EFAULT:
                printf("Error: Memory Write Error...exiting\n");
                break;
            case ENOTTY:
                printf("Error: Invalid device or Request type...exiting\n");
                break;
            case EINVAL:
                printf("Error: Invalid REQUEST...exiting\n");
                break;
            case EAGAIN:
                printf("Error: Drive not ready...exiting\n");
                break;
            default:
                printf("Error: %d\n", errno);
	    	    break;
	    }
    }
    
    for (i = tochdr.cdth_trk0; i <= tochdr.cdth_trk1; i++) {
        tocentry.cdte_track = i;
        tocentry.cdte_format = CDROM_MSF;
        ioctl(drive, CDROMREADTOCENTRY, &tocentry);
        cdtoc[i-1].min = tocentry.cdte_addr.msf.minute;
        cdtoc[i-1].sec = tocentry.cdte_addr.msf.second;
        cdtoc[i-1].frame = tocentry.cdte_addr.msf.frame;
        cdtoc[i-1].frame += cdtoc[i-1].min*60*75;
        cdtoc[i-1].frame += cdtoc[i-1].sec*75;
    }

    tocentry.cdte_track = 0xAA;
    tocentry.cdte_format = CDROM_MSF;
    ioctl(drive, CDROMREADTOCENTRY, &tocentry);
    cdtoc[tochdr.cdth_trk1].min = tocentry.cdte_addr.msf.minute;
    cdtoc[tochdr.cdth_trk1].sec = tocentry.cdte_addr.msf.second;
    cdtoc[tochdr.cdth_trk1].frame = tocentry.cdte_addr.msf.frame;
    cdtoc[tochdr.cdth_trk1].frame += cdtoc[tochdr.cdth_trk1].min*60*75;
    cdtoc[tochdr.cdth_trk1].frame += cdtoc[tochdr.cdth_trk1].sec*75;
    close(drive);

    return tochdr.cdth_trk1;
}

#endif //LINUX_H

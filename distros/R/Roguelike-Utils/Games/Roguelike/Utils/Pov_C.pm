package Games::Roguelike::Utils::Pov_C;

# broken undil perl 5.8
# use Exporter qw(import);

BEGIN {
        require Exporter;
        *{import} = \&Exporter::import;
	our @EXPORT = qw(checkpov_c distance findclose_c);
}

our $VERSION = '0.4.' . [qw$Revision: 236 $]->[1];

use Inline C => <<'END_C';

#include <math.h>

#define printf PerlIO_stdoutf

AV * mapav(SV *mapr) {
	AV *map; 
//        SV **v;
        if (SvTYPE(mapr) != SVt_RV)
                croak("map must be a reference");

        mapr = SvRV(mapr);
        if (SvTYPE(mapr) != SVt_PVAV)
                croak("map must be an array ref");

	map = (AV*) mapr;

//	v = av_fetch((AV *) map, 0, 0); 
//	if (!v || SvTYPE(*v) != SVt_RV || (SvTYPE(SvRV(*v)) != SVt_PVAV)) {
//		croak("map should be doubly-indexed array");
//	}
	return map;
}

double distance(int x1, int y1, int x2, int y2) {
        return sqrt((x1-x2)*(x1-x2)+(y1-y2)*(y1-y2));
}

int hv_int(HV *h, char *k, U32 klen, int errv) {
	SV ** svp = hv_fetch(h, k, klen, 0);
	if (svp) return SvIV(*svp);
	return errv;
}

SV * hv_sv(HV *h, char *k, U32 klen) {
        SV ** svp = hv_fetch(h, k, klen, 0);
        if (svp) return *svp;
        return NULL;
}


char mapat(AV *map, int x, int y) {
	SV **v;
	v = av_fetch(map, (I32) x, 0); if (!v) return 0;
	v = av_fetch((AV *) SvRV(*v), (I32) y, 0); if (!v) return 0;
        if (SvTYPE(*v) == SVt_PVHV) {
		v = hv_fetch((HV *) v, "sym", 3, 0);
		if (!v) return 0;
	}
 	if (!SvPOK(*v)) croak("not a string %d, %d", x, y);
	char *pc = SvPVX(*v);
	if (pc) return *pc;
	return 0;

}

int checkpov_c(int vx, int vy, int rx, int ry, SV *mapr, char *blocksyms, bool debug) {
	AV * map = mapav(mapr);
	if (!map) return 0;
	double dist = distance(vx, vy, rx, ry);
        double dx = rx-vx;
        double dy = ry-vy;

	char ok[4];
	memset(ok, 1, 4);
	double i;
        for (i = 1; i <= dist; i+=0.5) {
                double tx = vx+(i/dist)*dx;    // delta-fraction of distance
                double ty = vy+(i/dist)*dy;

		double x[4];
		double y[4];

                x[0] = (0.1+tx);               // not quite the corners
                y[0] = (0.1+ty);
                x[1] = (0.9+tx);
                y[1] = (0.9+ty);
                x[2] = (0.9+tx);
                y[2] = (0.1+ty);
                x[3] = (0.1+tx);
                y[3] = (0.9+ty);

		int j;
                for (j = 0; j < 4; ++j) {
                        if (!ok[j]) continue;
                        if ((((int)x[j]) == rx) && (((int)y[j]) == ry)) {
				if (debug) printf("%.1f: sub %d: %f,%f SAME\n",i,j,x[j],y[j]);
                                continue;
                        }
                        if (dx != 0 && dy != 0 && (fabs(dx/dy) > 0.1) && (fabs(dy/dx) > 0.1)) {
                                // allow peeking around corners if target is near the edge
                                if (lround(x[j]) == rx && lround(y[j]) == ry && i >= (dist-1)) {
					if (debug) printf("%.1f: sub %d: %f,%f PEEK\n",i,j,x[j],y[j]);
					continue;
				}
                        }
                        if (strchr(blocksyms,mapat(map, x[j],y[j]))) {
				if (debug) printf("%.1f: sub %d: %f,%f WALL\n",i,j,x[j],y[j]);
                                ok[j] = 0;
                        } else {
				if (debug) printf("%.1f: sub %d: %f,%f OK\n",i,j,x[j],y[j]);
			}
                }
		if (!ok[0] && !ok[1] && !ok[2] && !ok[3]) {
			return 0;
		}
        }
	return 1;
}

#define MAXP 1024
typedef struct {int x;int y;} point;

point f[MAXP];
point DD[9] = {{0,-1},{0,1},{1,0},{-1,0},{1,-1},{1,1},{-1,-1},{-1,1},{0,0}};

void findclose_c (SV *r, int x1, int y1, int x2, int y2) {
        if (SvTYPE(r) != SVt_RV) croak("world must be a ref");
	r = SvRV(r);
        if (SvTYPE(r) != SVt_PVHV) croak("world must be a hash ref");
	int w = hv_int((HV *) r, "w", 1, 0);
	int h = hv_int((HV *) r, "h", 1, 0);
	if (!w || !h) croak("world must have w & h");

	SV * mapr = hv_sv((HV *)r, "m", 1);
	if (!mapr) croak("world must have map m");
	AV * map = mapav(mapr);
	if (!map) croak("world must have array ref map m");

	bool bread[w*h]; memset(bread, 0, sizeof(bool)*w*h);

        // flood fill return closest you can get to x2/y2 without going thru a barrier

	int p = 0; f[p].x=x1; f[p].y=y1;
	int mindist = distance(x1, y1, x2, y2);
	int tx, ty;
	point c = {x1, y1};
	while (p >= 0) {
		int d;
		c = f[p--];
		for (d = 0; d < 8; ++d) {
			tx = DD[d].x+c.x;	
			ty = DD[d].y+c.y;
			char sym = mapat(map, tx, ty);
			printf("%c", sym);
			if (sym == '#' || !sym) continue;
			if (tx < 0 || ty <0|| tx > w || ty >h) continue;
			if (bread[ty*w+tx]) continue;
			bread[ty*w+tx]=1;
			if (tx == x2 && ty == y2) break;
			int td;
			if ((td = distance(tx, ty, x2, y2)) < mindist)	{
				c.x=tx;
				c.y=ty;
			}
			if (p >= MAXP) croak("path is too long");
			f[++p].x=tx; f[p].y=ty;
		}		
		if (tx == x2 && ty == y2) break;
	}
    	Inline_Stack_Vars;
    	Inline_Stack_Reset;
    	Inline_Stack_Push(newSViv(c.x));
    	Inline_Stack_Push(newSViv(c.y));
    	Inline_Stack_Push(newSViv(mindist));
   	Inline_Stack_Done;
   	Inline_Stack_Return(3);
}

END_C

1;

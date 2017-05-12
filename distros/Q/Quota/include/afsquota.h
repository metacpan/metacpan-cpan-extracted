/*
 *  prototype declarations for AFS quota interface
 */

int afs_check(void);
int afs_getquota(char *path, int *maxQuota, int *blocksUsed);
int afs_setqlim(char *path, int maxQuota);

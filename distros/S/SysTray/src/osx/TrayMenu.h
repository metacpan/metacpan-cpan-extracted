#import <Cocoa/Cocoa.h>

@interface TrayMenu : NSObject {
    @private
        NSStatusItem *_statusItem;
        NSString     *_path;
        NSString     *_tooltip;
        int          _isClick;
}
- (void)setInitialIcon: (NSString *)s;
- (void)setInitialTooltip:(NSString *)s;
- (void)changeIcon: (NSString *)s;
- (void)setToolTip: (NSString *)s;
- (int)isClicked;
- (void)invalidateClick;
- (void)removeIcon;
- (void)createIcon;
@end 
"""Golden fixture: module-level free function (no class)."""


def make_token(prefix: str, length: int = 16) -> str:
    return prefix + "x" * length
